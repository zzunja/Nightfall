local Animation = require('common/animation');

local RingAnimation = require('components/gameplay/ringanimation');

-- Lane position map
local Lanes = {
  1.5 / 6,
  2.5 / 6,
  3.5 / 6,
  4.5 / 6,
  1 / 3,
  2 / 3,
};

local makeCrit = function(useSDVX) 
  return Animation:new({
    alpha = (useSDVX and 1.5) or 1.2,
    centered = true,
    fps = 60,
    frameCount = (useSDVX and 19) or 17,
    path = ('gameplay/hit_animation/critical/%s'):format(
      (useSDVX and 'y') or 'b'
    ),
    scale = (useSDVX and 0.525) or 0.65,
  });
end

local makeNear = function(useSDVX)
  return Animation:new({
    alpha = (useSDVX and 1.25) or 1,
    centered = true,
    fps = (useSDVX and 72) or 74,
    frameCount = (useSDVX and 22) or 17,
    path = ('gameplay/hit_animation/near/%s'):format(
      (useSDVX and 'p') or 'b'
    ),
    scale = (useSDVX and 0.8) or 0.975,
  });
end

---@class HitAnimationClass
local HitAnimation = {
  -- HitAnimation constructor
  ---@param this HitAnimationClass
  ---@param window Window
  ---@return HitAnimation
  new = function(this, window)
    local useSDVX = getSetting('sdvxHitAnims', false);

    ---@class HitAnimation : HitAnimationClass
    ---@field window Window
    local t = {
      crit = makeCrit(useSDVX),
      hold = RingAnimation:new(),
      near = makeNear(useSDVX),
      preview = {
        rotation = 0,
        line = {
          x1 = 0,
          x2 = 0,
          y1 = 0,
          y2 = 0,
        },
      },
      ---@type table<string, AnimationState[]>
      states = {
        crit = {},
        hold = {},
        near = {},
      },
      useSDVX = useSDVX,
      window = window,
    };

    for name, part in pairs(t.states) do
      for btn = 1, 6 do
        if (name ~= 'hold') then
          part[btn] = {};

          for i = 1, 8 do
            part[btn][i] = {
              frame = 1,
              queued = false,
              timer = 0,
            };
          end
        else
          part[btn] = {
            active = false,
            alpha = 0,
            effect = {
              alpha = 1,
              playIn = true,
              playOut = false,
              timer = 0,
            },
            inner = {
              frame = 1,
              timer = 0,
            },
            timer = 0,
          };
        end
      end
    end

    setmetatable(t, this);
    this.__index = this;

    return t;
  end,

  -- Queues a hit animation to be played
  ---@param this HitAnimation
  ---@param btn integer # `0` = BTA, `1` = BTB, `2` = BTC, `3` = BTD, `4` = FXL, `5` = FXR
  ---@param rating integer # `0` = Miss, `1` = Near, `2` = Crit, `3` = Idle
  trigger = function(this, btn, rating)
    if (rating == 2) then
      for _, state in ipairs(this.states.crit[btn + 1]) do
        if (not state.queued) then state.queued = true; break; end
      end
    elseif (rating == 1) then
      for _, state in ipairs(this.states.near[btn + 1]) do
        if (not state.queued) then state.queued = true; break; end
      end
    end
  end,

  -- Transformation helper function
  ---@param this HitAnimation
  ---@param lane number # From `Lanes` map
  ---@param isPreview boolean
  transform = function(this, lane, isPreview)
    local t = (isPreview and this.preview) or gameplay.critLine;

    gfx.Translate(
      t.line.x1 + (t.line.x2 - t.line.x1) * lane,
      t.line.y1 + (t.line.y2 - t.line.y1) * lane
    );
    gfx.Rotate(-t.rotation);
    this.window:scale();
  end,

  -- Play the given animation
  ---@param this HitAnimation
  ---@param dt deltaTime
  ---@param animation Animation
  ---@param lane number # From `Lanes` map
  ---@param state AnimationState
  ---@param isPreview boolean
  play = function(this, dt, animation, lane, state, isPreview)
    gfx.Save();

    this:transform(lane, isPreview);

    animation:start(dt, state);

    gfx.Restore();
  end,

  -- Updates skin settings
  ---@param this HitAnimation
  update = function(this)
    local resX, resY = game.GetResolution();
    local isPortrait = resY > resX;
    local useSDVX = getSetting('sdvxHitAnims', false);

    this.preview.line.x1 = resX * ((isPortrait and 0.095) or 0.282);
    this.preview.line.x2 = resX * ((isPortrait and 0.905) or 0.718);
    this.preview.line.y1 = resY * ((isPortrait and 0.707) or 0.941);
    this.preview.line.y2 = resY * ((isPortrait and 0.707) or 0.941);
    this.preview.rotation = 0;

    if (useSDVX ~= this.useSDVX) then
      this.crit = makeCrit(useSDVX);
      this.near = makeNear(useSDVX);
      this.hold = RingAnimation:new();

      this.states.near[1].frame = 1;
      this.states.near[1].queued = false;
      this.states.near[1].timer = 0;

      this.states.crit[1].frame = 1;
      this.states.crit[1].queued = false;
      this.states.crit[1].timer = 0;

      this.states.hold[6].active = false;
      this.states.hold[6].timer = 0;
      this.states.hold[6].inner.frame = 1;
      this.states.hold[6].inner.timer = 0;

      this.useSDVX = useSDVX;
    end
  end,

  -- Renders the current component
  ---@param this HitAnimation
  ---@param dt deltaTime
  ---@param isPreview boolean
  render = function(this, dt, isPreview)
    local crit = this.states.crit;
    local hold = this.states.hold;
    local near = this.states.near;

    if (isPreview) then
      this:update();
      
      hold[6].active = true;

      this:play(dt, this.hold, Lanes[6], hold[6], isPreview);
    end

    for btn = 1, 6 do
      ---@param state AnimationState
      for _, state in ipairs(crit[btn]) do
        if (state.queued) then
          this:play(dt, this.crit, Lanes[btn], state, isPreview);
        end
      end

      ---@param state AnimationState
      for _, state in ipairs(near[btn]) do
        if (state.queued) then
          this:play(dt, this.near, Lanes[btn], state, isPreview);
        end
      end

      if (not isPreview) then
        hold[btn].active = gameplay.noteHeld[btn];

        this:play(dt, this.hold, Lanes[btn], hold[btn]);
      end
    end
  end,
};

return HitAnimation;
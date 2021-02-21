local CONTROL_LIST = require('constants/controls');

local _ = {
  cache = {
    resX = 0,
    resY = 0
  },
  buttonY = 0,
  hoveredPage = nil,
  maxPages = 8,
  mousePosX = 0,
  mousePosY = 0,
  selectedPage = nil
};

_.initializeButton = function(self)
  loadFont('medium');

  local button = {
    [1] = {
      label = New.Label({ text = 'GENERAL', size = 36 }),
      page = 'general',
    },
    [2] = {
      label = New.Label({ text = 'SONG SELECT', size = 36 }),
      page = 'songSelect',
    },
    [3] = {
      label = New.Label({ text = 'GAMEPLAY SETTINGS', size = 36 }),
      page = 'gameplaySettings',
    },
    [4] = {
      label = New.Label({ text = 'GAMEPLAY', size = 36 }),
      page = 'gameplay',
    },
    [5] = {
      label = New.Label({ text = 'PRACTICE MODE', size = 36 }),
      page = 'practiceMode',
    },
    [6] = {
      label = New.Label({ text = 'RESULTS', size = 36 }),
      page = 'results',
    },
    [7] = {
      label = New.Label({ text = 'MULTIPLAYER', size = 36 }),
      page = 'multiplayer',
    },
    [8] = {
      label = New.Label({ text = 'NAUTICA', size = 36 }),
      page = 'nautica',
    },
    activePage = 1,
    startEsc = New.Label({ text = '[START]  /  [ESC]', size = 24 }),
    close = New.Label({ text = 'CLOSE', size = 24 }),
    maxWidth = 0,
  };

  button.drawButton = function(self, x, y, i, isActive)
    gfx.BeginPath();

    alignText('left');
    self[i].label:draw({
      x = x,
      y = y,
      alpha = (isActive and 255) or 80,
      color = (isActive and 'normal') or 'white',
    });

    if (_:mouseClipped(x - 20, y - 10, self[i].label.w + 40, self[i].label.h + 30)) then
      _.hoveredPage = i;
    end

    if (self[i].label.w > self.maxWidth) then
      self.maxWidth = self[i].label.w;
    end

    return self[i].label.h * 2;
  end

  return button;
end

_.initializeControls = function(self)
  local controls = {
    general = {},
    songSelect = {},
    gameplaySettings = {},
    gameplay = {},
    practiceMode = {},
    results = {},
    multiplayer = {},
    nautica = {},
  };

  for category, list in pairs(controls) do
    for i = 1, #CONTROL_LIST[category] do
      list[i] = {};

      loadFont('normal');
      list[i].action = New.Label({
        text = CONTROL_LIST[category][i].action,
        size = 24,
      });

      loadFont('medium');
      list[i].controller = New.Label({
        text = CONTROL_LIST[category][i].controller,
        size = 24,
      });
      list[i].keyboard = New.Label({
        text = CONTROL_LIST[category][i].keyboard,
        size = 24,
      });

      if (CONTROL_LIST[category][i].lineBreak) then
        list[i].lineBreak = true;
      end

      if (CONTROL_LIST[category][i].note) then
        list[i].note = true;
      end
    end
  end

  controls.drawControls = function(self, category, initialX, initialY)
    local list = self[category];
    local x = initialX;
    local y = initialY;

    gfx.BeginPath();
    alignText('left');

    _.controller:draw({
      x = x,
      y = y,
      color = 'white',
    });
    _.keyboard:draw({
      x = x + 350,
      y = y,
      color = 'white',
    });

    y = y + 60;

    for i = 1, #list do
      list[i].controller:draw({
        x = x,
        y = y,
        color = (list[i].note and 'white') or 'normal',
      });

      list[i].keyboard:draw({
        x = x + 350,
        y = y,
        color = (list[i].note and 'white') or 'normal',
      });

      list[i].action:draw({
        x = x + 700,
        y = y,
        color = 'white',
      });

      if ((i ~= #list) and (not list[i].note)) then
        drawRectangle({
          x = x + 1,
          y = y + 38,
          w = _.layout.scaledW / 1.65,
          h = 2,
          alpha = 100,
          color = 'normal',
          fast = true,
        });
      end

      if (list[i].lineBreak) then
        y = y + 90;
      else
        y = y + 45;
      end
    end
  end

  return controls;
end

_.initializeLayout = function(self)
  local layout = {};

  layout.setupLayout = function(self)
    local resX, resY = game.GetResolution();

    if ((_.cache.resX ~= resX) or (_.cache.resY ~= resY)) then
      self.scaledW = 1920;
      self.scaledH = self.scaledW * (resY / resX);
      self.scalingFactor = resX / self.scaledW;

      _.cache.resX = resX;
      _.cache.resY = resY;
    end
  end

  layout:setupLayout();

  return layout;
end

_.initializeAll = function(self, selection)
  self.mouseClipped = function(self, x, y, w, h)
    local scaledX = x * self.layout.scalingFactor;
    local scaledY = y * self.layout.scalingFactor;
    local scaledW = scaledX + (w * self.layout.scalingFactor);
    local scaledH = scaledY + (h * self.layout.scalingFactor);

    return (self.mousePosX > scaledX)
      and (self.mousePosY > scaledY)
      and (self.mousePosX < scaledW)
      and (self.mousePosY < scaledH);
  end

  loadFont('medium');
  self.heading = New.Label({ text = 'CONTROLS', size = 60 });
  self.controller = New.Label({ text = 'CONTROLLER', size = 30 });
  self.keyboard = New.Label({ text = 'KEYBOARD', size = 30 });

  self.button = self:initializeButton();
  self.controls = self:initializeControls();
  self.layout = self:initializeLayout();
end

_.render = function(self, deltaTime, showControls, selectedPage)
  if (not showControls) then return end;

  self.selectedPage = selectedPage or 1;

  self.layout:setupLayout();

  self.mousePosX, self.mousePosY = game.GetMousePos();

  drawRectangle({
    x = 0,
    y = 0,
    w = self.layout.scaledW,
    h = self.layout.scaledH,
    alpha = 170,
    color = 'black',
    fast = true,
  });

  local x = self.layout.scaledW / 20;
  local y = self.layout.scaledH / 20;

  gfx.BeginPath();
  alignText('left');
  self.heading:draw({
    x = x - 3,
    y = y,
    color = 'white',
  });

  self.buttonY = y + self.heading.h * 2;
  self.hoveredPage = nil;

  for category = 1, self.maxPages do
    self.buttonY = self.buttonY + self.button:drawButton(
      x,
      self.buttonY,
      category,
      category == self.selectedPage
    );
  end

  drawRectangle({
    x = x + self.button.maxWidth + 75,
    y = y + (self.heading.h * 2) + 10,
    w = 4,
    h = self.layout.scaledH * 0.475,
    color = 'white',
  });

  self.controls:drawControls(
    self.button[self.selectedPage].page,
    x + self.button.maxWidth + 150,
    y + (self.heading.h * 2)
  );

  gfx.BeginPath();
  alignText('left');
  self.button.startEsc:draw({
    x = x,
    y = y + self.layout.scaledH - (self.layout.scaledH / 7),
    color = 'normal',
  });

  self.button.close:draw({
    x = x + self.button.startEsc.w + 8,
    y = y + self.layout.scaledH - (self.layout.scaledH / 7),
    color = 'white',
  });

  return self.hoveredPage;
end

return _;
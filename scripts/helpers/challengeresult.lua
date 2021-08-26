local Clears = require('constants/clears');
local Difficulties = require('constants/difficulties');

local ScoreNumber = require('components/common/scorenumber');

local jacketFallback = gfx.CreateSkinImage('loading.png', 0);

-- Get the date format template string
---@return string
local getDateFormat = function()
  local dateFormat = getSetting('dateFormat', 'DAY-MONTH-YEAR');

  if (dateFormat == 'DAY-MONTH-YEAR') then
    return '%d-%m-%y';
  elseif (dateFormat == 'MONTH-DAY-YEAR') then
    return '%m-%d-%y';
  elseif (dateFormat == 'YEAR-MONTH-DAY') then
    return '%y-%m-%d';
  else
    return '%d-%m-%y';
  end
end

-- Get the clear name
---@param res result
---@return string
local getClear = function(res)
  local badge = res.badge or 0;

	if (badge == 0) then return 'EXIT'; end

	local gauge = (res.gauge or 0) * 100;
	local gType = res.gauge_type or res.flags or 0;

  if ((gType == 0) and (gauge < 70)) then return 'CRASH'; end

  return Clears[badge].clear;
end

-- Get the difficulty name
---@param chart Chart
---@return string
local getDiff = function(chart)
  return Difficulties[getDiffIndex(chart.jacketFallback, chart.difficulty)];
end

-- Get the gauge percentage
---@param chart Chart
---@return string
local getGauge = function(chart)
	local gauge = (chart.gauge or 0) * 100;
	local gType = chart.gauge_type or chart.flags or 0;

  if (gType == 1) then
		return ('%.1f%% (EXC)'):format(gauge);
	elseif (gType == 2) then
		return ('%.1f%% (PMS)'):format(gauge);
	elseif (gType == 3) then
		return ('%.1f%% (BLS)'):format(gauge);
	end

	return ('%.1f%%'):format(gauge);
end

-- Formats the requirements
---@param res result
local getReqs = function(res)
  local r = {};
  
  for req in res.requirement_text:gmatch('[^\n]+') do
    r[#r + 1] = makeLabel('norm', req);
  end

  return r;
end

-- Formats a challenge
---@param res result
---@return ChalInfo
local formatChallenge = function(res)
  ---@class ChalInfo
  ---@field reqs Label[]
  local c = {
    completion = makeLabel('num', ('%d%%'):format(res.avgPercentage), 24),
    date = makeLabel('num', os.date(getDateFormat(), os.time()), 24),
    player = makeLabel('norm', getSetting('displayName', 'GUEST')),
    reqs = getReqs(res),
    result = makeLabel('norm', (res.passed and 'PASS') or 'FAIL'),
    title = makeLabel('norm', res.title, 36),
  };

  return c;
end

-- Formats a chart
---@param res result
---@return ChalChart[]
local formatCharts = function(res)
  local charts = {};

  ---@param chart ChartResult
  for i, chart in ipairs(res.charts) do
    ---@class ChalChart
    local c = {
      bpm = makeLabel('num', chart.bpm, 24),
      clear = makeLabel('norm', getClear(chart)),
      completion = makeLabel('num', ('%d%%'):format(chart.percent), 24),
      critical = ScoreNumber:new({
        digits = 5,
        size = 24,
        val = chart.perfects,
      });
      difficulty = makeLabel('norm', getDiff(chart)),
      error = ScoreNumber:new({
        digits = 5,
        size = 24,
        val = chart.misses,
      });
      gauge = makeLabel('num', getGauge(chart), 24),
      grade = makeLabel('norm', chart.grade),
      jacket = gfx.LoadImageJob(
        chart.jacketPath,
        jacketFallback,
        1000,
        1000
      ),
      maxChain = ScoreNumber:new({
        digits = 5,
        size = 24,
        val = chart.maxCombo,
      });
      near = ScoreNumber:new({
        digits = 5,
        size = 24,
        val = chart.goods,
      });
      level = makeLabel('num', ('%02d'):format(chart.level), 24),
      result = makeLabel('norm', (chart.passed and 'PASS') or 'FAIL'),
      score = ScoreNumber:new({ size = 62, val = chart.score }),
      timer = 0,
      title = makeLabel('jp', chart.title, 36),
    };

    if (chart.bpm:find('-') and (chart.speedModType == 2)) then
      c.cmod = makeLabel('med', 'CMOD PLAY');
    end

    charts[i] = c;
  end

  return charts;
end

return {
  formatChallenge = formatChallenge,
  formatCharts = formatCharts,
};
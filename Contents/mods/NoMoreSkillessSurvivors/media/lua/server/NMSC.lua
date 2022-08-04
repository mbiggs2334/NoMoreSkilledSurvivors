local skillList = {
    "Fitness",
    "Strength",
    "Sprinting",
    "Lightfoot",
    "Nimble",
    "Sneak",
    "Axe",
    "Blunt",
    "SmallBlunt",
    "LongBlade",
    "SmallBlade",
    "Spear",
    "Maintenance",
    "Woodwork",
    "Cooking",
    "Farming",
    "Doctor",
    "Electricity",
    "MetalWelding",
    "Mechanics",
    "Tailoring",
    "Aiming",
    "Reloading",
    "Fishing",
    "Trapping",
    "PlantScavenging",
}

--booleans
local blankSlate;
local progressiveSkills;
local progressiveLevels;
local keepProfession;


local blankSlateExceptionOne;
local blankSlateExceptionTwo;
local progressiveSkillsTime;
local progressiveLevelsTime;
local minimumSkillSelection;
local maxSkillSelection;
local minimumLevel;
local maxLevel;
local playerProfession;
local playerProfessionInfo;

local function checkIfSkillIsStored(skillSet, x)
    local skillPresent = false;
    for _, skill in ipairs(skillSet) do
        if skillList[x] == skill then
            skillPresent = true;
        end
    end
    return skillPresent;
end

local function checkForDuplicates(skillSet)
    local x = ZombRand(#skillList);
    if checkIfSkillIsStored(skillSet, x) or x == (blankSlateExceptionOne - 1) or x == (blankSlateExceptionTwo - 1)
    then
        x = checkForDuplicates(skillSet)
    end
    return x
end

local function ApplyChanges(specificPlayer)
    local selectedSkills = {};
    local player = getSpecificPlayer(specificPlayer);

    --resets all skills to zero if blank state is enabled
    if blankSlate then
        print(tostring( keepProfession));
        --skips over the blank state exception/profession skills, if any
        if (blankSlateExceptionOne > 1 or blankSlateExceptionTwo > 1) and (not keepProfession) then
            print("You shouldn't see this");
            print("You shouldn't see this");
            print("You shouldn't see this");
            print("You shouldn't see this");
            print("You shouldn't see this");
            print("You shouldn't see this");
            print("You shouldn't see this");
            for i = 0, #skillList do
                local skipIteration = false;
                if i == (blankSlateExceptionOne - 1) or i == (blankSlateExceptionTwo - 1) then skipIteration = true end
                if not skipIteration then
                    player:level0(Perks[skillList[i]]);
                    player:getXp():setXPToLevel(Perks[skillList[i]], 0);
                end
            end
        elseif keepProfession then
            for i = 0, #skillList do
                local skill = tostring(skillList[i])
                if not string.find(playerProfessionInfo, skill) then
                    player:level0(Perks[skillList[i]]);
                    player:getXp():setXPToLevel(Perks[skillList[i]], 0);
                end
            end
        else
            for i = 0, #skillList do
                player:level0(Perks[skillList[i]]);
                player:getXp():setXPToLevel(Perks[skillList[i]], 0);
            end
        end
    end

    --Grabs the skill names to be altered and adds them to a temp storage
    while #selectedSkills < maxSkillSelection do
        local skipIteration = false;
        local skillIndex = ZombRand(#skillList) - 1;

        if #selectedSkills > 0 then
            skillIndex = checkForDuplicates(selectedSkills);
        end

        if keepProfession then
            local skillString = tostring(skillList[skillIndex]);
            if string.find(playerProfessionInfo, skillString) then
                skipIteration = true;
            end
        end

        if not skipIteration then
            table.insert(selectedSkills, skillList[skillIndex]);
        end
    end

    --ZombRand() below seems to never select the true maxLevel value but only one below it
    --Add one just to be sure the true value can be reached
    --maxLevel = maxLevel + 1;

    --applies the level changes based on the skills in selectedSkills
    for _, skillName in ipairs(selectedSkills) do
        local randomizedSkillLevel = ZombRand(minimumLevel, maxLevel);

        --Add a little more rng into the mix
        local rand = ZombRand(1, 5);
        if rand == 1 or rand == 3 then
            if randomizedSkillLevel > 1 then
                randomizedSkillLevel = randomizedSkillLevel - 1;
            end
        elseif rand == 4 then
            if randomizedSkillLevel < 10 then
                randomizedSkillLevel = randomizedSkillLevel + 1;
            end
        end

        --Ensure the randomizedSkillLevel isn't under/over the min/max skill level
        if randomizedSkillLevel > maxLevel then
            randomizedSkillLevel = maxLevel;
        end
        if randomizedSkillLevel < minimumLevel then
            randomizedSkillLevel = minimumLevel;
        end

        --Applies randomized levels to selected skills
        for i = 1, randomizedSkillLevel do
            player:LevelPerk(Perks[skillName], false)
        end
        player:getXp():setXPToLevel(Perks[skillName], randomizedSkillLevel);
    end

end

local function getRoughMonthEstimateSinceGameStart()
    local gameTime = GameTime:getInstance();
    local startingMonth = gameTime:getStartMonth();
    local startingYear = gameTime:getStartYear();
    local startingDay = gameTime:getStartDay();
    local currentMonth = gameTime:getMonth();
    local currentYear = gameTime:getYear();
    local currentDay = gameTime:getDay();
    local roughDaysSinceStart;
    local SECONDS_IN_A_DAY = 86400;
    local date1 = os.time({year = startingYear, month = startingMonth, day = startingDay});
    local date2 = os.time({year = currentYear, month = currentMonth, day = currentDay});
    roughDaysSinceStart = math.ceil(os.difftime(date2, date1) / SECONDS_IN_A_DAY);
    return math.floor((roughDaysSinceStart / 30) + 0.5);
end

--timeline length will be in months
local function calculateProgressiveNumbers(levelOrSkill, timelineLength, minimum)
    local monthsSinceStart = getRoughMonthEstimateSinceGameStart();
    if monthsSinceStart >= timelineLength then
        return levelOrSkill;
    else
        local x = (levelOrSkill / timelineLength) * monthsSinceStart;
        local roundedDown = math.ceil(x + 0.5);
        if minimum > roundedDown then
            roundedDown = minimum;
        end
        if levelOrSkill  < roundedDown then
            roundedDown = levelOrSkill;
        end
        return roundedDown;
    end
end


local function alterPlayerStats(player)
    --Make sure the player is a fresh spawn before we do anything
    if getSpecificPlayer(player):getHoursSurvived() < 0.005 then

        -- ensures sandbox options are up to date
        blankSlate = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.removeBasePerks"):getValue();
        blankSlateExceptionOne = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.skillOneUneffected"):getValue();
        blankSlateExceptionTwo = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.skillTwoUneffected"):getValue();
        progressiveSkills = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.progressiveSkills"):getValue();
        progressiveSkillsTime = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.progressiveSkillSelection"):getValue() + 2;
        progressiveLevels = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.progressiveMaxLevel"):getValue();
        progressiveLevelsTime = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.progressiveMaxLevelSelection"):getValue() + 2;
        maxSkillSelection = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.numberOfSkills"):getValue() - 1;
        minimumSkillSelection = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.minimumNumberOfSkills"):getValue() - 1;
        maxLevel = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.maxLevels"):getValue() - 1;
        minimumLevel = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.minimumLevel"):getValue() - 1;
        keepProfession = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.keepProfession"):getValue();

        --safe check for if the user makes the minimum higher than the maximum
        if minimumLevel > maxLevel then
            maxLevel = minimumLevel;
        end
        if minimumSkillSelection > maxSkillSelection then
            maxSkillSelection = minimumSkillSelection;
        end

        --Grabs updated numbers for progressive options
        if progressiveLevels then
            maxLevel = calculateProgressiveNumbers(maxLevel, progressiveLevelsTime, minimumLevel);
        end
        if progressiveSkills then
            maxSkillSelection = calculateProgressiveNumbers(maxSkillSelection, progressiveSkillsTime, minimumSkillSelection);
        end

        -- grab player profession/profession info
        if keepProfession then
            playerProfession = getSpecificPlayer(player):getDescriptor():getProfession();
            playerProfessionInfo = tostring(ProfessionFactory.getProfession(playerProfession):getXPBoostMap());
        end

        ApplyChanges(player);
    end
end

--local function StartNMSS()
    --blankSlate = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.removeBasePerks"):getValue();
    --blankSlateExceptionOne = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.skillOneUneffected"):getValue();
    --blankSlateExceptionTwo = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.skillTwoUneffected"):getValue();
    --progressiveSkills = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.progressiveSkills"):getValue();
    --progressiveSkillsTime = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.progressiveSkillSelection"):getValue();
    --progressiveLevels = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.progressiveMaxLevel"):getValue();
    --progressiveLevelsTime = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.progressiveMaxLevelSelection"):getValue();
    --maxSkillSelection = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.numberOfSkills"):getValue();
    --minimumSkillSelection = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.minimumNumberOfSkills"):getValue() - 1;
    --maxLevel = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.maxLevels"):getValue();
    --minimumLevel = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.minimumLevel"):getValue() - 1;
--
--    Events.OnCreatePlayer.Add(alterPlayerStats);
--end
--
--Events.OnGameStart.Add(StartNMSS);

Events.OnCreatePlayer.Add(alterPlayerStats);
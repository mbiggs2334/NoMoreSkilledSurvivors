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
local keepProfessionRNG;
local keepTraits;
local keepTraitsRNG;


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
local playerTraits;
local playerTraitsInfo;
local selectedSkills;


local function removeTraitAndProfessionFromSkillList(skillName)
    for i = 0, #selectedSkills do
        if selectedSkills[i] == skillName then
            table.remove(selectedSkills, i);
        end
    end
end

--resets all skills to zero if blank state is enabled
local function handleBlankSlate(player)
    if blankSlate then
        --skips over the blank state exception/profession skills, if any
        if (blankSlateExceptionOne > 1 or blankSlateExceptionTwo > 1) or (keepProfession or keepTraits) then
            for i = 0, #skillList do
                local skipIteration = false;
                if not keepTraits and not keepProfession then
                    if (i == (blankSlateExceptionOne - 1)) or (i == (blankSlateExceptionTwo - 1)) then skipIteration = true end
                end
                if keepTraits and not skipIteration then
                    for k,v in pairs(playerTraitsInfo) do
                        if skillList[i] == k then
                            --removeTraitAndProfessionFromSkillList(k);
                            skipIteration = true;
                        end
                    end
                end
                if keepProfession and not skipIteration then
                    for k,v in pairs(playerProfessionInfo) do
                        if skillList[i] == k then
                            --removeTraitAndProfessionFromSkillList(k);
                            skipIteration = true;
                        end
                    end
                end
                if not skipIteration then
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
end


local function createSkillListCopy()
    local skillListCopy = {};
    for i = 0, #skillList do
        skillListCopy[i] = skillList[i];
    end
    return skillListCopy
end


--Grabs the skill names to be altered and returns them in a table
local function grabSkillNames()
    local skillsToReturn = {};
    local skillsCopy = createSkillListCopy()

    while #skillsToReturn < maxSkillSelection do
        local skipIteration = false;
        local skillIndex = ZombRand(#skillsCopy);

        if not skipIteration then
            table.insert(skillsToReturn, skillsCopy[skillIndex]);
            table.remove(skillsCopy, skillIndex);
        end
    end

    return skillsToReturn;
end


local function adjustLevelForProfessionAndTraits(currentLevel, skillName, isTrait)
    local newLevel = currentLevel
    if isTrait then
        if playerTraitsInfo[skillName] then
            newLevel = currentLevel + playerTraitsInfo[skillName];
        end
    else
        if playerProfessionInfo[skillName] then
            newLevel = currentLevel + playerProfessionInfo[skillName];
        end
    end
    return newLevel
end


--converts XPMapBoost string to a workable table, for both traits and professions
local function convertStringToKeyValueTable(stringArg, isTrait)
    local stringCopy = stringArg;
    if isTrait == true then
        for k,v in string.gmatch(stringCopy, "(%w+)=(-?%w+)") do
            if playerTraitsInfo[k] then
                playerTraitsInfo[k] = playerTraitsInfo[k] + tonumber(v);
            else
                playerTraitsInfo[k] = tonumber(v);
            end
        end
    else
        local table = {};

        for k,v in string.gmatch(stringCopy, "(%w+)=(%w+)") do
            table[k] = v;
        end

        return table
    end

end


--applies the level changes based on the skills in selectedSkills
local function applyLevelChanges(player, skillCollection)
    for _, skillName in ipairs(skillCollection) do
        local randomizedSkillLevel = ZombRand(minimumLevel, maxLevel);


        --Add a little more rng into the mix
        local rand = ZombRand(10);
        if rand == 1 or rand == 4 then
            randomizedSkillLevel = randomizedSkillLevel - 1;
        end
        if rand == 8 or rand == 10 then
            randomizedSkillLevel = randomizedSkillLevel + 1;
        end


        --Ensure the randomizedSkillLevel isn't under/over the min/max skill level
        if randomizedSkillLevel > maxLevel then
            randomizedSkillLevel = maxLevel;
        end
        if randomizedSkillLevel < minimumLevel then
            randomizedSkillLevel = minimumLevel;
        end


        --applies profession/trait changes if blank slate is enabled
        if keepProfession and blankSlate then
            randomizedSkillLevel = adjustLevelForProfessionAndTraits(randomizedSkillLevel, skillName, false);
        end
        if keepTraits and blankSlate then
            randomizedSkillLevel = adjustLevelForProfessionAndTraits(randomizedSkillLevel, skillName, true);
        end

        if not keepTraits and not blankSlate then
            if type(playerTraitsInfo[skillName]) == "number" and playerTraitsInfo[skillName] < 0 then
                randomizedSkillLevel = randomizedSkillLevel + playerTraitsInfo[skillName];
            end
        end

        -- Final check to make sure the randomized number is not over 10 or under 0
        if randomizedSkillLevel > 10 then
            randomizedSkillLevel = 10;
        elseif randomizedSkillLevel < 0 then
            randomizedSkillLevel = 0;
        end

        --Applies levels to selected skills
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


-- get and store trait skill values
local function getTraitMapBoost(arrayOfTraits)
    local traitStrings = arrayOfTraits;
    for _,v in pairs(traitStrings) do
        local boostMap = TraitFactory.getTrait(v):getXPBoostMap();
        if boostMap:size() > 0 then
            local string = tostring(boostMap);
            convertStringToKeyValueTable(string, true);
        end
    end
end


-- extract the traits that come back from player:getTraits();
local function extractTraitStrings(traitCollectionString)
    local array = {};
    local string = traitCollectionString;
    for word in string.gmatch(playerTraits, '%a+%s*%a*%s*%a*%s*%a*') do
        if word ~= "TraitCollection" and word then
            table.insert(array, word);
        end
    end
    return array;
end


local function ApplyChanges(specificPlayer)
    local player = getSpecificPlayer(specificPlayer);
    selectedSkills = grabSkillNames();
    handleBlankSlate(player);
    applyLevelChanges(player, selectedSkills);
end


-- ensures grabbed sandbox variables are up to date
local function updateLocalVariables()
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
    --keepProfessionRNG = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.keepProfessionRNG"):getValue();
    keepTraits = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.keepTraits"):getValue();
    --keepTraitsRNG = getSandboxOptions():getOptionByName("NoMoreSkillessCharacters.keepTraitsRNG"):getValue();
end


local function alterPlayerStats(player)
    --Make sure the player is a fresh spawn before we do anything
    if getSpecificPlayer(player):getHoursSurvived() < 0.005 then
        updateLocalVariables();
        
        --safe check for if the user makes the minimum higher than the maximum
        if minimumLevel > maxLevel then
            maxLevel = minimumLevel;
        end
        if minimumSkillSelection > maxSkillSelection then
            maxSkillSelection = minimumSkillSelection;
        end

        --Grabs updated numbers for progressive options, if enabled
        if progressiveLevels then
            maxLevel = calculateProgressiveNumbers(maxLevel, progressiveLevelsTime, minimumLevel);
        end
        if progressiveSkills then
            maxSkillSelection = calculateProgressiveNumbers(maxSkillSelection, progressiveSkillsTime, minimumSkillSelection);
        end

        -- grab player profession and profession info
        playerProfessionInfo = {};
        playerProfession = getSpecificPlayer(player):getDescriptor():getProfession();
        local tempString = tostring(ProfessionFactory.getProfession(playerProfession):getXPBoostMap());
        playerProfessionInfo = convertStringToKeyValueTable(tempString, false);

        -- grab player traits and trait info
        playerTraitsInfo = {};
        playerTraits = tostring(getPlayer():getTraits());
        local playerTraitArray = extractTraitStrings(playerTraits);
        getTraitMapBoost(playerTraitArray);


        ApplyChanges(player);
    end
end

Events.OnCreatePlayer.Add(alterPlayerStats);
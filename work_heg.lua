local H = require "packages/hegemony/util"
local U = require "packages/utility/utility"
local extension = Package:new("work_heg")
extension.extensionName = "hegemony_diy"
extension.game_modes_whitelist = { 'nos_heg_mode', 'new_heg_mode' }

Fk:loadTranslationTable{
  ["work_heg"] = "国战-工作室专属",
  ["wk_heg"] = "日月",
}

local liuye = General(extension, "wk_heg__liuye", "wei", 3)
local poyuan = fk.CreateTriggerSkill{
  name = "wk_heg__poyuan",
  anim_type = "offensive",
  events = {fk.Damage, fk.DamageCaused},
  can_trigger = function (self, event, target, player, data)
    if not (target == player and player:hasSkill(self) and player:isAlive()) then return false end
    if event == fk.Damage then
      return data.to ~= player and not data.to.dead and #data.to:getCardIds("e") > 0
    else
      if not H.isBigKingdomPlayer(data.to) then return false end
      local events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data[1].from == player and H.isBigKingdomPlayer(e.data[1].to)
      end, Player.HistoryTurn)
      return #events == 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.Damage then
      return player.room:askForSkillInvoke(player, self.name, nil, "#wk_heg__poyuan-discard")
    else
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      local id = room:askForCardChosen(player, data.to, "e", self.name)
      room:throwCard(id, self.name, data.to, player)
    else
      data.damage = data.damage + 1
    end
  end,
}

local choulue = fk.CreateTriggerSkill{
  name = "wk_heg__choulue",
  anim_type = "offensive",
  events = {fk.Damaged, fk.TargetSpecified},
  can_trigger = function (self, event, target, player, data)
    if event == fk.Damaged then
      return player == target and player:hasSkill(self) and player:getMark("@!yinyangfish") < player.maxHp
    else
      return player:hasSkill(self) and H.compareKingdomWith(player, target) and #AimGroup:getAllTargets(data.tos) == 1
        and data.card:isCommonTrick() and player:getMark("@!yinyangfish") ~= 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, event == fk.Damaged and "#wk_heg__choulue-getfish" or "#wk_heg__choulue-twice")
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      H.addHegMark(room, player, "yinyangfish")
    else
      room:removePlayerMark(player, "@!yinyangfish")
      if player:getMark("@!yinyangfish") == 0 then
        player:loseFakeSkill("yinyangfish_skill&")
      end
      data.additionalEffect = 1
    end
  end,
}

liuye:addSkill(poyuan)
liuye:addSkill(choulue)
Fk:loadTranslationTable{
  ["wk_heg__liuye"] = "刘晔",
  ["#wk_heg__liuye"] = "画策谁迎",
  ["designer:wk_heg__liuye"] = "教父&卧雏",

  ["wk_heg__poyuan"] = "破垣",
  [":wk_heg__poyuan"] = "①当你对其他角色造成伤害后，你可弃置其一张装备区内的牌；②当你于一回合首次对大势力角色造成伤害时，此伤害+1。",
  ["wk_heg__choulue"] = "筹略",
  [":wk_heg__choulue"] = "①当你受到伤害后，若你的“阴阳鱼”标记数小于你体力上限，你可获得一个“阴阳鱼”标记；②当与你势力相同的角色使用普通锦囊牌指定唯一目标后，你可移去一个“阴阳鱼”标记，令此牌结算两次。",

  ["#wk_heg__poyuan-discard"] = "破垣：是否弃置受伤角色装备区内一张牌",
  ["poyuan_discard-hand"] = "令其弃置一张手牌",
  ["poyuan_discard-equip"] = "弃置其一张装备区内的牌",

  ["#wk_heg__choulue-getfish"] = "筹略：是否获得一个“阴阳鱼”标记",
  ["#wk_heg__choulue-twice"] = "筹略：是否移去一个“阴阳鱼”标记，令此牌结算两次",

  ["$wk_heg__poyuan1"] = "砲石飞空，坚垣难存。",
  ["$wk_heg__poyuan2"] = "声若霹雳，人马俱摧。",
  ["$wk_heg__choulue1"] = "筹画所料，无有不中。",
  ["$wk_heg__choulue2"] = "献策破敌，所谋皆应。",
  ["~wk_heg__liuye"] = "功名富贵，到头来，不过黄土一抔…",
}

local dongyun = General(extension, "wk_heg__dongyun", "shu", 3, 3, General.Male)
local yizan = fk.CreateTriggerSkill{
  name = "wk_heg__yizan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Discard
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      if player.room:askForSkillInvoke(player, self.name, nil, "#wk_heg__yizan-invoke") then
        local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
          return (p:getHandcardNum() < player:getHandcardNum()) end), Util.IdMapper)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__yizan-choose", self.name, true)
          self.cost_data = to[1]
          if #to > 0 then
            return true
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    to:drawCards(math.min(player:getHandcardNum() - #to.player_cards[Player.Hand], 5), self.name)
    room:setPlayerMark(player, "wk_heg__yizan-phase", self.cost_data)
  end,
}

local yizan_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__yizan_delay",
  anim_type = "special",
  events = {fk.EventPhaseEnd},
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(self) and player.phase == Player.Discard and player:getMark("wk_heg__yizan-phase") ~= 0) then return false end 
    local logic = player.room.logic
    local x = 0
    logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.skillName == "game_rule" then
          x = x + #move.moveInfo
          if x > 1 then return true end
        end
      end
      return false
    end, Player.HistoryTurn)
    return x > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("wk_heg__yizan-phase"))
    local throw_num = #to.player_cards[Player.Hand] - to.maxHp
    if throw_num > 0 then
      room:askForDiscard(to, throw_num, throw_num, false, self.name, false)
    end
  end,
}

local juanshe = fk.CreateTriggerSkill{
  name = "wk_heg__juanshe",
  anim_type = "recover",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    -- local current = player.room.current
    local events = target.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e) 
      local use = e.data[1]
      return use.from == target.id 
    end, Player.HistoryTurn)
    return #events < target:getMaxCards() and H.compareKingdomWith(player, target) 
      and target.phase == Player.Finish and player:hasSkill(self) and not target:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wk_heg__juanshe-invoke")
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:askForDiscard(target, 1, 1, false, self.name, false)
    if target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
    room:setPlayerMark(target, "@@wk_heg__juanshe-prohibit", 1)
  end,

  refresh_events = {fk.EventPhaseChanging, fk.BuryVictim, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      return player.room.current:getMark("@@wk_heg__juanshe-prohibit") > 0 and data.from == Player.NotActive
    elseif event == fk.BuryVictim or event == fk.Damaged then
      return player == target and player:hasSkill(self)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      player.room:setPlayerMark(player.room.current, "@@wk_heg__juanshe-prohibit", 0)
    elseif event == fk.BuryVictim or event == fk.Damaged then
      for _, p in ipairs(player.room.alive_players) do
        if p:getMark("@@wk_heg__juanshe-prohibit") > 0 then
          player.room:setPlayerMark(p, "@@wk_heg__juanshe-prohibit", 0)
        end
      end
    end
  end,
}

local juanshe_prohibit = fk.CreateProhibitSkill{
  name = "#wk_heg__juanshe_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@wk_heg__juanshe-prohibit") == 0 then return false end 
    local subcards = Card:getIdList(card)
    return #subcards > 0 and table.every(subcards, function(id)
      return table.contains(player:getCardIds(Player.Hand), id)
    end)
  end,
}

dongyun:addCompanions("ld__jiangwanfeiyi")
yizan:addRelatedSkill(yizan_delay)
juanshe:addRelatedSkill(juanshe_prohibit)
dongyun:addSkill(yizan)
dongyun:addSkill(juanshe)
Fk:loadTranslationTable{
  ["wk_heg__dongyun"] = "董允",
  ["#wk_heg__dongyun"] = "匡主正堂",
  ["designer:wk_heg__dongyun"] = "教父&修功&风箫",

  ["wk_heg__yizan"] = "翼赞",
  [":wk_heg__yizan"] = "弃牌阶段开始时，你可令一名手牌数小于你的角色将手牌摸至与你相同（至多摸五张），然后此阶段结束时，若你于此阶段内弃置过牌，其将手牌弃至体力上限。",
  ["wk_heg__juanshe"] = "蠲奢",
  [":wk_heg__juanshe"] = "与你势力相同角色的结束阶段，若其本回合使用牌数小于其手牌上限，你可令其弃置一张手牌并回复1点体力，然后直至其回合开始或你受到伤害，其不能使用手牌。",

  ["@@wk_heg__juanshe-prohibit"] = "蠲奢 禁用手牌",

  ["#wk_heg__yizan_delay"] = "翼赞",
  ["#wk_heg__yizan-invoke"] = "翼赞：是否令一名手牌数小于你的角色将手牌摸至与你相同，然后其根据你的弃牌情况执行对应操作。",
  ["#wk_heg__yizan-choose"] = "翼赞：选择一名手牌数小于你的角色，令其将手牌摸至与你相同。",
  ["#wk_heg__juanshe-invoke"] = "蠲奢：是否令当前回合角色弃置一张手牌，然后其回复1点体力。",

  ["$wk_heg__yizan1"] = "公事为重，宴席不去也罢。",
  ["$wk_heg__yizan2"] = "还是改日吧。",

  ["$wk_heg__juanshe1"] = "自古，就是邪不胜正！。",
  ["$wk_heg__juanshe2"] = "主公面前，岂容小人搬弄是非。",

  ["~wk_heg__dongyun"] = "大汉，要亡于宦官之手了…",
}

local luotong = General(extension, "wk_heg__luotong", "wu", 3)
local mingzheng = fk.CreateTriggerSkill{
  name = "wk_heg__mingzheng",
  anim_type = "drawcard",
  events = {fk.GeneralRevealed, fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(self) and H.compareKingdomWith(target, player) and not target.dead) then return false end
    if event == fk.GeneralRevealed then
      return H.getGeneralsRevealedNum(target) == 2
    else
      return target.phase == Player.Play
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local targets = table.map(table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) and p ~= target end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askForChoosePlayers(target, targets, 1, 1, "#wk_heg__mingzheng-choose", self.name, false)
        local p = room:getPlayerById(to[1])
        room:askForCardsChosen(target, p, 0, 0, {
          card_data = {
            { "$Hand", p:getCardIds(Player.Hand) }
          }
        }, self.name, "wk_heg__mingzheng-hand::"..to[1])
      end
    end
    if event == fk.GeneralRevealed then
      target:reset()
      room:addPlayerMark(target, "@!yinyangfish", 1)
      target:addFakeSkill("yinyangfish_skill&")
      target:prelightSkill("yinyangfish_skill&", true)
    end
  end,
}

local yujian = fk.CreateTriggerSkill{
  name = "wk_heg__yujian",
  anim_type = "control",
  events = {fk.Damage},
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(self) and target ~= player and data.from.phase == Player.Play and H.compareKingdomWith(player, data.to)) then return false end
    local events = player.room.logic:getActualDamageEvents(2, function(e)
      return H.compareKingdomWith(e.data[1].to, player) and data.from == player.room.current and data.from and data.from.phase == Player.Play
    end, Player.HistoryTurn)
    return #events == 1
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local current = room.current
    if target.hp <= player.hp then
      U.swapHandCards(room, player, player, current, self.name)
      room:setPlayerMark(player, "@@wk_heg__yujian_exchange-turn", 1)
    end
    if H.getGeneralsRevealedNum(target) == 2 and room:askForChoice(player, {"wk_heg__yujian_hide::" .. target.id, "Cancel"}, self.name) ~= "Cancel" then
      for _, p in ipairs({target}) do
        local isDeputy = H.doHideGeneral(room, player, p, self.name)
        room:setPlayerMark(p, "@wk_heg__yujian_reveal-turn", H.getActualGeneral(p, isDeputy))
        local record = type(p:getMark(MarkEnum.RevealProhibited .. "-turn")) == "table" and p:getMark(MarkEnum.RevealProhibited .. "-turn") or {}
        table.insert(record, isDeputy and "d" or "m")
        room:setPlayerMark(p, MarkEnum.RevealProhibited .. "-turn", record)
      end
    end
  end,
}

local yujian_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__yujian_delay",
  anim_type = "special",
  events = {fk.TurnEnd},
  can_trigger = function (self, event, target, player, data)
    return player:getMark("@@wk_heg__yujian_exchange-turn") > 0 and not player.dead and not player.room.current.deat
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local current = room.current
    U.swapHandCards(room, player, player, current, self.name)
  end
}

yujian:addRelatedSkill(yujian_delay)
luotong:addSkill(mingzheng)
luotong:addSkill(yujian)
Fk:loadTranslationTable{
  ["wk_heg__luotong"] = "骆统",
  ["#wk_heg__luotong"] = "达弼政辅",
  ["designer:wk_heg__luotong"] = "教父",

  ["wk_heg__mingzheng"] = "明政",
  [":wk_heg__mingzheng"] = "与你势力相同的角色：1.明置武将牌后，若其武将牌均明置，其复原武将牌，然后获得一个“阴阳鱼”标记; 2.出牌阶段开始时，其观看除其外一名与你势力相同的角色的手牌。",
  ["wk_heg__yujian"] = "御谏",
  [":wk_heg__yujian"] = "其他角色于其出牌阶段内首次对与你势力相同的角色造成伤害后，你可依次执行每个满足条件的项：1.若其体力值不大于你，你可以与其交换手牌，若如此做，此回合结束时，你与其交换手牌；"..
  "2.若其武将牌均明置，你可以暗置其一张武将牌且直至本回合结束不能明置之。",

  ["#wk_heg__mingzheng-choose"] = "明政：选择一名与你势力相同的其他角色观看手牌",
  ["wk_heg__mingzheng-hand"] = "明政：观看%dest的手牌",
  ["wk_heg__yujian_hide"] = "暗置%dest一张武将牌且本回合不能明置",

  ["#wk_heg__yujian_delay"] = "御谏",
  ["@@wk_heg__yujian_exchange-turn"] = "御谏 交换手牌",

  ["#wk_heg__yujian-invoke"] = "御谏：你可根据条件与当前回合角色交换手牌或暗置当前回合角色武将牌",
  ["@wk_heg__yujian_reveal-turn"] = "御谏 禁亮",

  ["$wk_heg__mingzheng1"] = "仁政如水，可润万物",
  ["$wk_heg__mingzheng2"] = "为官一任，当造福一方",
  ["$wk_heg__yujian1"] = "臣代天子牧民，闻苛自当谏之。",
  ["$wk_heg__yujian2"] = "为将者死战，为臣者死谏。",
  ["~wk_heg__luotong"] = "而立之年，奈何早逝。",
}

local jvshou = General(extension, "wk_heg__jvshou", "qun", 3)

local tugui = fk.CreateTriggerSkill{
  name = "wk_heg__tugui",
  anim_type = "defensive",
  events = {fk.AfterCardsMove, fk.EnterDying, fk.EventPhaseEnd},
  can_trigger = function (self, event, target, player, data)
    local ret = false
    if event == fk.AfterCardsMove then
      if not player:hasSkill(self) or not player:isKongcheng() then return end
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
              ret = true
              break
            end
          end
        end
      end
      if ret then
        return table.find(player.room.alive_players, function(p) return player:distanceTo(p) == 1 and not p:isKongcheng() end)
      end
    elseif event == fk.EnterDying then
      if player == target and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
        ret = true
      end
      if ret then
        return table.find(player.room.alive_players, function(p) return player:distanceTo(p) == 1 and not p:isKongcheng() end)
      end
    else
      return player:hasSkill(self) and player == target and player.phase == Player.Play and player:getMark("wk_heg__tugui") ~= 0 
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.AfterCardsMove or event == fk.EnterDying then
      return player.room:askForSkillInvoke(player, self.name, nil, "#wk_heg__tugui-ask")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove or event == fk.EnterDying then
      local targets = table.map(table.filter(room.alive_players, function(p) return player:distanceTo(p) == 1 and not p:isKongcheng() end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__tugui-choose", self.name, false)
        local card = room:askForCardChosen(player, room:getPlayerById(to[1]), "h", self.name)
        room:obtainCard(player.id, card, false, fk.ReasonPrey)
        player:showCards(card)
        local mark = player:getTableMark("wk_heg__tugui")
        table.insert(mark, {player.id, card})
        room:setPlayerMark(player, "wk_heg__tugui", mark)
      end
    else
      for _, t in ipairs(player:getMark("wk_heg__tugui")) do
        local p = player.room:getPlayerById(t[1])
        if p and table.contains(p:getCardIds("he"), t[2]) then
          H.removeGeneral(room, player, player.deputyGeneral == "wk_heg__jvshou")
          break
        end
      end
      room:setPlayerMark(player, "wk_heg__tugui", 0)
    end
  end,
}

local yingshou = fk.CreateTriggerSkill{
  name = "wk_heg__yingshou",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player == target and player.phase == Player.Finish and player:hasSkill(self)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return H.compareKingdomWith(player, p) end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__yingshou-choose")
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      to:drawCards(2, self.name)
      room:setPlayerMark(to, "@@wk_heg__yingshou", 1)
    end
  end,
}

local yingshou_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__yingshou_delay",
  anim_type = "special",
  events = {fk.Damage},
  can_trigger = function (self, event, target, player, data)
    return data.from:getMark("@@wk_heg__yingshou") > 0 and not data.from:isNude() and data.from.phase == Player.Play and player:hasSkill(self)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:askForDiscard(data.from, 1, 1, true, self.name, false)
  end,

  refresh_events = {fk.EventPhaseEnd},
  can_refresh = function (self, event, target, player, data)
    return target:getMark("@@wk_heg__yingshou") > 0 and target.phase == Player.Play
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(target, "@@wk_heg__yingshou", 0)
  end,
}

yingshou:addRelatedSkill(yingshou_delay)
jvshou:addSkill(tugui)
jvshou:addSkill(yingshou)

Fk:loadTranslationTable{
  ["wk_heg__jvshou"] = "沮授",
  ["#wk_heg__jvshou"] = "志北挽魂",
  ["designer:wk_heg__jvshou"] = "教父&小曹神",

  ["wk_heg__tugui"] = "图归",
  [":wk_heg__tugui"] = "①每回合限一次，当你失去最后的手牌后或当你进入濒死状态后，你可获得与你距离为1的其他角色的一张手牌并展示之；②出牌阶段结束时，若你未失去以此法获得的所有牌，你移除此武将牌。",
  ["wk_heg__yingshou"] = "营守",
  [":wk_heg__yingshou"] = "结束阶段，你可令一名与你势力相同的角色摸两张牌，若如此做，当其于下个出牌阶段内造成伤害后，其弃置一张牌。",

  ["#wk_heg__tugui-ask"] = "图归：是否获得与你距离为1的其他角色的一张手牌",
  ["#wk_heg__tugui-choose"] = "图归：选择一名与你距离为1的其他角色",

  ["#wk_heg__yingshou_delay"] = "营守",
  ["#wk_heg__yingshou-choose"] = "营守：选择一名与你势力相同的角色",
  ["@@wk_heg__yingshou"] = "营守",

  ["$wk_heg__tugui1"] = "矢志于北，尽忠于国。",
  ["$wk_heg__tugui2"] = "命系袁氏，一心向北。",
  ["$wk_heg__yingshou1"] = "由缓至急，循循而进。",
  ["$wk_heg__yingshou2"] = "事须缓图，欲速不达也。",
  ["~wk_heg__jvshou"] = "身处河南，魂归河北…",
}

--- 推举
---@param room Room
---@param player ServerPlayer
---@param skillName string
---@return ServerPlayer?
local function DoElectedChange(room, player, skillName)
  local kingdom = player:getMark("__heg_kingdom")
  if kingdom == "wild" then
    kingdom = player:getMark("__heg_init_kingdom")
  end
  local generals = room:findGenerals(function(g)
    return Fk.generals[g].kingdom == kingdom or Fk.generals[g].subkingdom == kingdom
  end, 1)
  local general = room:askForGeneral(player, generals, 1, true) ---@type string
  room:sendLog{
    type = "#ElectedChangeLog",
    from = player.id,
    arg = general,
    arg2 = skillName,
    toast = true,
  }
  local targets = table.map(table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end), Util.IdMapper)
  room:sortPlayersByAction(targets)
  local ret
  for _, pid in ipairs(targets) do
    local p = room:getPlayerById(pid)
    local choices = {"Cancel"}
    if p.general ~= "anjiang" and not p.general:startsWith("ld__lord") and not general.subkingdom then
      table.insert(choices, "#elected_change_main:::" .. general)
    end
    if p.deputyGeneral ~= "anjiang" then
      table.insert(choices, "#elected_change_deputy:::" .. general)
    end
    local choice = room:askForChoice(p, choices, "ElectedChange", "#elected_change-ask:" .. player.id .. "::" .. general)
    if choice ~= "Cancel" then
      if choice:startsWith("#elected_change_main") then
        generals = {H.getActualGeneral(p, false)}
        room:changeHero(p, general, false, false, true, false, false)
        room.logic:trigger("fk.GeneralTransformed", p, general)
      else
        generals = {H.getActualGeneral(p, true)}
        room:changeHero(p, general, false, true, true, false, false)
        room.logic:trigger("fk.GeneralTransformed", p, general)
      end
      ret = p
      break
    end
  end
  room:returnToGeneralPile(generals)
  return {ret, general}
end

Fk:loadTranslationTable{
  ["ElectedChange"] = "推举",
  ["#Elected"] = "推举了",
  ["#ElectedChangeLog"] = "%from 由于 “%arg2”，推举了 %arg",
  ["#elected_change_main"] = "选用：将%arg作为主将",
  ["#elected_change_deputy"] = "选用：将%arg作为副将",
  ["#elected_change-ask"] = "%src 推举了 %arg，你可 选用 为你的主将或副将",
}

local chenqun = General(extension, "wk_heg__chenqun", "wei", 3)
local dingpin = fk.CreateTriggerSkill{
  name = "wk_heg__dingpin",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and player == target and not player.chained and player.phase == Player.Finish
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__dingpin-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:setChainState(true)
    local to = room:getPlayerById(self.cost_data)
    if not to.chained then
      to:setChainState(true)
    end
    room:setPlayerMark(to, "_wk_heg__dingpin", player.id)
    to:gainAnExtraTurn(true, self.name)
  end,
}
local dingpin_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__dingpin_delay",
  events = {fk.EventPhaseStart, fk.TurnEnd, fk.EventPhaseChanging},
  anim_type = "special",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return (target.phase == Player.Play and target:getCurrentExtraTurnReason() == "wk_heg__dingpin" and target:getMark("_wk_heg__dingpin") == player.id and H.compareKingdomWith(player, target))
    else
      return target == player and target:getCurrentExtraTurnReason() == "wk_heg__dingpin"
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      local p_table = DoElectedChange(room, target, self.name)
    elseif event == fk.TurnEnd then
      if target:getHandcardNum() > target.hp then
        room:askForDiscard(target, target:getHandcardNum() - target.hp, target:getHandcardNum() - target.hp, false, self.name, false)
      end
      if target:getHandcardNum() < target.hp then
        target:drawCards(target.hp - target:getHandcardNum(), self.name)
      end
      room:setPlayerMark(target, "_wk_heg__dingpin", 0)
      target:turnOver()
    else
      local excludePhases = { Player.Start, Player.Judge, Player.Draw, Player.Discard, Player.Finish }
      for _, phase in ipairs(excludePhases) do
        table.removeOne(player.phases, phase)
      end
    end
  end,
}
dingpin:addRelatedSkill(dingpin_delay)

local faen = fk.CreateTriggerSkill{
  name = "wk_heg__faen",
  anim_type = "offensive",
  events = {fk.TurnedOver, fk.ChainStateChanged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and ((event == fk.TurnedOver and not target.faceup) or (event == fk.ChainStateChanged and target.chained and(H.hasShownSkill(player, self) or player == target))) and H.compareKingdomWith(player, target)
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TurnedOver then
      return player.room:askForSkillInvoke(player, self.name, nil, "#wk_heg__faen_turn-invoke")
    else
      return player.room:askForSkillInvoke(target, self.name, nil, "#wk_heg__faen_chained-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnedOver then
      room:askForDiscard(target, 2, 2, true, self.name, false)
      target:turnOver()
    else
      local card = room:askForCard(target, 1, 1, true, self.name, true)
      room:recastCard(card, target, self.name)
    end
  end,
}
chenqun:addSkill(dingpin)
chenqun:addSkill(faen)

chenqun:addCompanions("hs__caopi")
chenqun:addCompanions("hs__simayi")
Fk:loadTranslationTable{
  ["wk_heg__chenqun"] = "陈群",
  ["designer:wk_heg__chenqun"] = "教父&635",

  ["wk_heg__dingpin"] = "定品",
  [":wk_heg__dingpin"] = "结束阶段，若你未横置，你可横置你与一名与你势力相同的角色，令其于此回合结束后执行一个仅有出牌阶段的额外回合，此额外回合：1.出牌阶段开始时，其推举；2.回合结束时，其将手牌数摸或弃至体力值，然后叠置。<br />" ..
  "<font color = 'gray'>推举：推举角色展示一张与其势力相同的武将牌，每名与其势力相同的角色选择是否将此武将牌作为其新的主将或副将。" ..
  "若有角色选择是，称为该角色<u>选用</u>，停止对后续角色的询问，结束推举流程。</font>",
  ["wk_heg__faen"] = "法恩",
  [":wk_heg__faen"] = "与你势力相同的角色：1.横置后，其可重铸一张牌；2.叠置后，你可令其弃置两张牌，然后其平置。",

  ["@@wk_heg__dingpin_extra"] = "定品",
  ["#wk_heg__dingpin-choose"] = "定品：你可以选择一名与你势力相同的角色，横置你与其，令其于此回合结束后执行一个仅有出牌阶段的额外的回合",
  ["#wk_heg__dingpin_delay"] = "定品",

  ["#wk_heg__faen_turn-invoke"] = "法恩：是否令其弃置两张牌，然后其平置",
  ["#wk_heg__faen_chained-invoke"] = "法恩：是否重铸一张牌",

  ["$wk_heg__dingpin1"] = "取才赋职，论能行赏。",
  ["$wk_heg__dingpin2"] = "定品寻良骥，中正探人杰。",
  ["$wk_heg__faen1"] = "礼法容情，皇恩浩荡。",
  ["$wk_heg__faen2"] = "法理有度，恩威并施。",
  ["~wk_heg__chenqun"] = "吾身虽陨，典律昭彰。",
}

local xujing = General(extension, "wk_heg__xujing", "shu", 3, 3, General.Male)
local yuyan = fk.CreateTriggerSkill{
  name = "wk_heg__yuyan",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(self) or player.room.current == player then return end
    local n = 0
    for _, move in ipairs(data) do
      if move.to and move.to == player.id and move.from and move.from ~= player.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            n = n + 1
          end
        end
      end
    end
    if n > 0 then
      self.cost_data = n
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local current = room.current
    local n = self.cost_data
    local cards2
    if #player:getCardIds("he") <= n then
      cards2 = player:getCardIds("he")
    else
      cards2 = room:askForCard(player, n, n, true, self.name, false, ".",
        "#wk_heg__yuyan-give::"..current.id..":"..n)
    end
    room:moveCardTo(cards2, Card.PlayerHand, current, fk.ReasonGive, self.name, nil, false, player.id)
  end,
}
local yuyan_alliance = H.CreateAllianceSkill{
  name = "#wk_heg__yuyan_alliance",
  allow_alliance = function(self, from, to)
    return H.compareKingdomWith(from, to) and to:hasShownSkill(yuyan) and from:getHandcardNum() > to:getHandcardNum()
  end
}
local yuyan_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__yuyan_delay",
  events = {fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(yuyan.name) > 0 and H.compareKingdomWith(player, player.room.current)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if player:isWounded() and not player.dead then
      player.room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    else
      DoElectedChange(player.room, target, self.name)
    end
  end,
}

local caixia_filter = fk.CreateActiveSkill{
  name = "#wk_heg__caixia_filter",
  min_card_num = 1,
  max_card_num = 99,
  card_filter = function(self, to_select, selected)
    return table.every(selected, function(id)
      return Fk:getCardById(to_select).trueName == Fk:getCardById(id).trueName
    end) and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = Util.FalseFunc,
  can_use = Util.FalseFunc,
}
local caixia = fk.CreateTriggerSkill{
  name = "wk_heg__caixia",
  anim_type = "defensive",
  events = {fk.Damaged, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local result, dat = room:askForUseActiveSkill(player, "#wk_heg__caixia_filter", "#wk_heg__caixia", true)
    if result then
      self.cost_data = dat.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:showCards(self.cost_data)
    if not player.dead then
      player:drawCards(math.min(#self.cost_data, player.hp), self.name)
    end
  end,
}

yuyan:addRelatedSkill(yuyan_delay)
yuyan:addRelatedSkill(yuyan_alliance)
xujing:addSkill(yuyan)
caixia:addRelatedSkill(caixia_filter)
xujing:addSkill(caixia)
xujing:addCompanions("ld__fazheng")
Fk:loadTranslationTable{
  ["wk_heg__xujing"] = "许靖",
  ["#wk_heg__xujing"] = "尺瑜寸瑕",
  ["designer:wk_heg__xujing"] = "教父&635&二四",

  ["wk_heg__yuyan"] = "誉言",
  [":wk_heg__yuyan"] = "①你是与你势力相同且手牌数大于你的角色“合纵”的合法目标；②当你于回合外获得其他角色的牌后，你可将等量张牌交给当前回合角色，若如此做，此回合结束时，若其与你势力相同，你推举，若你已受伤，则改为回复1点体力。<br />"..
    "<font color = 'gray'>推举：推举角色展示一张与其势力相同的武将牌，每名与其势力相同的角色选择是否将此武将牌作为其新的主将或副将。" ..
  "若有角色选择是，称为该角色<u>选用</u>，停止对后续角色的询问，结束推举流程。</font>",
  ["wk_heg__caixia"] = "才瑕",
  [":wk_heg__caixia"] = "每回合限一次，当你造成或受到伤害后，你可展示任意张同名手牌，然后摸等量的牌（至多摸你体力值张）。",

  ["#wk_heg__yuyan-give"] = "誉言：交给 %dest 共计 %arg 张牌",
  ["#wk_heg__yuyan_delay"] = "誉言",
  ["#wk_heg__caixia_filter"] = "才瑕",
  ["#wk_heg__caixia"] = "才瑕：你可以展示任意张同名手牌，然后摸等量的牌。",

  ["$wk_heg__yuyan1"] = "君满腹才学，当为国之大器。",
  ["$wk_heg__yuyan2"] = "一腔青云之志，正待梦日之时。",
  ["$wk_heg__caixia1"] = "吾习扫天下之术，不善净一屋之秽。",
  ["$wk_heg__caixia2"] = "玉有十色五光，微瑕难掩其瑜。",
  ["~wk_heg__xujing"] = "时人如江鲫，所逐者功利尔…",
}

local buzhi = General(extension, "wk_heg__buzhi", "wu", 4)
buzhi.deputyMaxHpAdjustedValue = -1
local hongde = fk.CreateTriggerSkill{
  name = "wk_heg__hongde",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and #player:getCardIds("he") > 0 and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if #move.moveInfo > 1 and ((move.from == player.id and move.to ~= player.id) or
          (move.to == player.id and move.toArea == Card.PlayerHand)) then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local tos, id = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".", "#wk_heg__hongde-give", self.name, false)
    room:obtainCard(tos[1], id, false, fk.ReasonGive)
    if not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}

local shucai = fk.CreateTriggerSkill{
  name = "wk_heg__shucai",
  relate_to_place = 'd',
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Finish and #player:getCardIds("e") > 0 and
      table.find(player.room.alive_players, function(p) return player:canMoveCardsInBoardTo(p, "e") end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function (p)
      return player:canMoveCardsInBoardTo(p, "e")
    end), Util.IdMapper)
    targets = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__shucai-ask", self.name, true)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target = room:getPlayerById(self.cost_data)
    room:askForMoveCardInBoard(player, player, target, self.name, "e", player)
    if player.dead or target.dead then return end
    local p_table = DoElectedChange(room, player, self.name)
    if not player.dead and player.deputyGeneral.name == "wk_heg__buzhi" then
      room:setPlayerMark(player, "wk_heg__dingpan_notagged", 1)
      room:handleAddLoseSkills(player, "-wk_heg__shucai|wk_heg__shucai_notag|wk_heg__dingpan_notag", nil)
    end
  end,
}
local dingpan = fk.CreateActiveSkill{
  name = "wk_heg__dingpan",
  relate_to_place = 'm',
  anim_type = "offensive",
  can_use = function(self, player)
    local room = Fk:currentRoom()
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if p.kingdom == "wild" then
        n = n + 1
      end
    end
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < n + 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and
      (not H.compareKingdomWith(Fk:currentRoom():getPlayerById(to_select), Self))
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(1, self.name)
    local n = target:getAttackRange()
    local choices = {"wk_heg__dingpan_use:"..effect.from}
    if n <= #target:getCardIds("he") then
      table.insert(choices, "#wk_heg__dingpan_give:::"..n)
    end
    local choice = room:askForChoice(target, choices, self.name)
    if choice:startsWith("wk_heg__dingpan_use") then
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    else
      local cards = room:askForCardsChosen(target, target, n, n, "he", self.name)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, player.id)
    end
  end,
}

local shucai_notag = fk.CreateTriggerSkill{
  name = "wk_heg__shucai_notag",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  main_skill = shucai, -- 绷
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Finish and #player:getCardIds("e") > 0 and
      table.find(player.room.alive_players, function(p) return player:canMoveCardsInBoardTo(p, "e") end) and player:usedSkillTimes(self.main_skill.name, Player.HistoryPhase) == 0 -- 假装是一个技能
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function (p)
      return player:canMoveCardsInBoardTo(p, "e")
    end), Util.IdMapper)
    targets = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__shucai-ask", self.name, true)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target = room:getPlayerById(self.cost_data)
    room:askForMoveCardInBoard(player, player, target, self.name, "e", player)
    if player.dead or target.dead then return end
    DoElectedChange(room, player, self.name)
  end,
}
local shucai_retag = fk.CreateTriggerSkill{
  name = "#wk_heg__shucai_retag",
  events = {fk.EnterDying},
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player == target and player:getMark("wk_heg__dingpan_notagged") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-wk_heg__shucai_notag|-wk_heg__dingpan_notag|wk_heg__shucai", nil)
  end,
}
shucai_notag:addRelatedSkill(shucai_retag)
local dingpan_notag = fk.CreateActiveSkill{
  name = "wk_heg__dingpan_notag",
  anim_type = "offensive",
  main_skill = dingpan,
  can_use = function(self, player)
    local room = Fk:currentRoom()
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if p.kingdom == "wild" then
        n = n + 1
      end
    end
    return player:usedSkillTimes(self.main_skill.name, Player.HistoryPhase) < n + 1 -- 绷
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and
      (not H.compareKingdomWith(Fk:currentRoom():getPlayerById(to_select), Self))
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(1, self.name)
    local n = target:getAttackRange()
    local choices = {"wk_heg__dingpan_use:"..effect.from}
    if n <= #target:getCardIds("he") then
      table.insert(choices, "#wk_heg__dingpan_give:::"..n)
    end
    local choice = room:askForChoice(target, choices, self.name)
    if choice:startsWith("wk_heg__dingpan_use") then
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    else
      local cards = room:askForCardsChosen(target, target, n, n, "he", self.name)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, player.id)
    end
  end,
}

buzhi:addSkill(hongde)
buzhi:addSkill(shucai)
buzhi:addSkill(dingpan)
Fk:addSkill(shucai_notag)
Fk:addSkill(dingpan_notag)
Fk:loadTranslationTable{
  ["wk_heg__buzhi"] = "步骘",
  ["#wk_heg__buzhi"] = "博研沈深",
  ["designer:wk_heg__buzhi"] = "教父&风箫",

  ["wk_heg__hongde"] = "弘德",
  [":wk_heg__hongde"] = "每回合限一次，当你一次性获得或失去两张牌后，你可交给一名其他角色一张牌，然后摸一张牌。",
  ["wk_heg__dingpan"] = "定叛",
  [":wk_heg__dingpan"] = "主将技，出牌阶段限X次，你可令一名其他势力角色摸一张牌，然后其选择：1.交给你其攻击范围数张牌；2.你视为对其使用一张【杀】（X为野心家角色数+1）。",
  ["wk_heg__shucai"] = "疏才",
  [":wk_heg__shucai"] = "副将技，此武将牌上单独的阴阳鱼个数-1；结束阶段，你可将你装备区内一张牌移动至其他角色装备区内，然后推举并删除此武将牌所有技能标签至你进入濒死状态。<br />"..
  "<font color = 'gray'>推举：推举角色展示一张与其势力相同的武将牌，每名与其势力相同的角色选择是否将此武将牌作为其新的主将或副将。" ..
  "若有角色选择是，称为该角色<u>选用</u>，停止对后续角色的询问，结束推举流程。</font>",

  ["#wk_heg__hongde-give"] = "弘德：选择一名其他角色，交给其一张牌",
  ["#wk_heg__shucai-ask"] = "疏才：你可选择一名其他角色，将装备区内一张牌移动至其装备区内",
  ["wk_heg__dingpan_use"] = "视为%src对你使用【杀】",
  ["#wk_heg__dingpan_give"] = "交出%arg张牌",
  ["#wk_heg__shucai_retag"] = "疏才",

  ["wk_heg__dingpan_notag"] = "定叛",
  [":wk_heg__dingpan_notag"] = "出牌阶段限X次，你可令一名其他势力角色摸一张牌，然后其选择：1.交给你其攻击范围数张牌；2.你视为对其使用一张【杀】（X为野心家角色数+1）。",
  ["wk_heg__shucai_notag"] = "疏才",
  [":wk_heg__shucai_notag"] = "结束阶段，你可将你装备区内一张牌移动至其他角色装备区内，然后推举并删除此武将牌所有技能标签至你进入濒死状态。<br />"..
  "<font color = 'gray'>推举：推举角色展示一张与其势力相同的武将牌，每名与其势力相同的角色选择是否将此武将牌作为其新的主将或副将。" ..
  "若有角色选择是，称为该角色<u>选用</u>，停止对后续角色的询问，结束推举流程。</font>",

  ["$wk_heg__hongde1"] = "江南重义，东吴尚德。",
  ["$wk_heg__hongde2"] = "德无单行，福必双至。",
  ["$wk_heg__dingpan1"] = "从孙者生，从刘者死！",
  ["$wk_heg__dingpan2"] = "多行不义必自毙！",
  ["$wk_heg__shucai1"] = "督军之才，子明强于我甚多。",
  ["$wk_heg__shucai2"] = "此间重任，公卿可担之。",
  ["~wk_heg__buzhi"] = "交州已定，主公尽可放心。",
}

local simahui = General(extension, "wk_heg__simahui", "qun", 3, 3, General.Male)
local jianjie = fk.CreateTriggerSkill{
  name = "wk_heg__jianjie",
  events = {fk.GeneralRevealed},
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    if player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:hasSkill(self) then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), self.name) then return true end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "support")
    player:broadcastSkillInvoke(self.name)
    for i = 1, 2, 1 do
      local p_table = DoElectedChange(room, target, self.name)
      if p_table then 
        local p_player = p_table[1]
        local p_general = p_table[2]
        if i == 1 and p_player then
          room:setPlayerMark(p_player, "@wk_heg__jianjie1", p_general)
          room:handleAddLoseSkills(p_player, "wk_heg__huoji", nil)
        elseif i == 2 and p_player then
          room:setPlayerMark(p_player, "@wk_heg__jianjie2", p_general)
          room:handleAddLoseSkills(p_player, "wk_heg__lianhuan", nil)
        end
      end
    end
  end,
}

local jianjie_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__jianjie_delay",
  events = {fk.AfterSkillEffect},
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    if player:usedSkillTimes(jianjie.name, Player.HistoryGame) == 0 or not target then return false end
    if target:getMark("@wk_heg__jianjie2") ~= 0 then
      local general2 = target:getMark("@wk_heg__jianjie2")
      return table.contains(Fk.generals[general2]:getSkillNameList(), data.name)
    end
    if target:getMark("@wk_heg__jianjie1") ~= 0 then
      local general1 = target:getMark("@wk_heg__jianjie1")
      return table.contains(Fk.generals[general1]:getSkillNameList(), data.name)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local general1 = target:getMark("@wk_heg__jianjie1")
    local general2 = target:getMark("@wk_heg__jianjie2")
    if general1 ~= 0 and table.contains(Fk.generals[general1]:getSkillNameList(), data.name) then
      room:setPlayerMark(target, "@wk_heg__jianjie1", 0)
      room:handleAddLoseSkills(target, "-wk_heg__huoji")
    end
    if general2 ~= 0 and table.contains(Fk.generals[general2]:getSkillNameList(), data.name) then
      room:setPlayerMark(target, "@wk_heg__jianjie2", 0)
      room:handleAddLoseSkills(target, "-wk_heg__lianhuan")
    end
  end,
}

local jingqi = fk.CreateTriggerSkill{
  name = "wk_heg__jingqi",
  events = {fk.Damage, fk.ChainStateChanged},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0) then return false end
    if event == fk.Damage then
      return data.damageType ~= fk.NormalDamage
    else
      return target.chained
    end
  end,
  on_use = function(self, event, target, player, data)
    if not player.room.current.dead then
      player.room.current:drawCards(1, self.name)
    end
    if not player.dead and player ~= player.room.current then
      player:drawCards(1, self.name)
    end
  end
}

local wk_heg__huoji = fk.CreateViewAsSkill{
  name = "wk_heg__huoji",
  anim_type = "offensive",
  pattern = "fire_attack",
  prompt = "#huoji",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}

local wk_heg__lianhuan = fk.CreateActiveSkill{
  name = "wk_heg__lianhuan",
  mute = true,
  card_num = 1,
  min_target_num = 0,
  prompt = "#lianhuan",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Club and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local card = Fk:cloneCard("iron_chain")
      card:addSubcard(selected_cards[1])
      card.skillName = self.name
      return card.skill:canUse(Self, card) and card.skill:targetFilter(to_select, selected, selected_cards, card) and
      not Self:prohibitUse(card) and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), card)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke(self.name)
    if #effect.tos == 0 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:recastCard(effect.cards, player, self.name)
    else
      room:notifySkillInvoked(player, self.name, "control")
      room:sortPlayersByAction(effect.tos)
      room:useVirtualCard("iron_chain", effect.cards, player, table.map(effect.tos, function(id)
        return room:getPlayerById(id) end), self.name)
    end
  end,
}

simahui:addRelatedSkill(wk_heg__huoji)
simahui:addRelatedSkill(wk_heg__lianhuan)
jianjie:addRelatedSkill(jianjie_delay)
simahui:addSkill(jianjie)
simahui:addSkill(jingqi)
Fk:loadTranslationTable{
  ["wk_heg__simahui"] = "司马徽",
  ["designer:wk_heg__simahui"] = "教父&静谦&朱古力",
  ["wk_heg__jianjie"] = "荐杰",
  [":wk_heg__jianjie"] = "当你首次明置此武将牌后，你推举两次，以此法第一次/第二次选用的角色获得“火计”/“连环”直至其发动选用武将牌上的技能。",
  ["wk_heg__jingqi"] = "经奇",
  [":wk_heg__jingqi"] = "每回合限一次，当一名角色造成属性伤害或横置后，你可以与当前回合角色各摸一张牌。",

  ["@wk_heg__jianjie1"] = "荐杰 火计",
  ["@wk_heg__jianjie2"] = "荐杰 连环",
  ["#wk_heg__jianjie_delay"] = "荐杰",

  ["wk_heg__huoji"] = "火计",
  [":wk_heg__huoji"] = "你可将一张红色手牌当【火攻】使用",
  ["wk_heg__lianhuan"] = "连环",
  [":wk_heg__lianhuan"] = "你可将一张♣手牌当【铁索连环】使用或重铸",

  ["$wk_heg__jianjie1"] = "卧龙凤雏，二者得一，可安天下。",
  ["$wk_heg__jianjie2"] = "二人齐聚，汉室可兴。",
  ["$wk_heg__jingqi1"] = "好，很好，非常好！",
  ["$wk_heg__jingqi2"] = "您的话也很好！",

  ["~wk_heg__simahui"] = "这似乎，没那么好了…",
}

local huanfan = General(extension, "wk_heg__huanfan", "wei", 3)

local liance_viewas = fk.CreateViewAsSkill{
  name = "#wk_heg__liance_viewas",
  interaction = function()
    local names = {}
    local mark = Self:getMark("wk_heg__liance-phase")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id, true)
      if table.contains(mark, card.name) then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    if not Self:canUse(card) or Self:prohibitUse(card) then return end
    return card
  end,
}
local liance = fk.CreateTriggerSkill{
  name = "wk_heg__liance",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or not target.phase == Player.Play or player == target or player:isNude() then return false end
    local usedCardNames = {}
    return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      if table.contains(usedCardNames, e.data[1].card.name) then
        return use.from == target.id and (use.card.type == Card.TypeTrick or use.card.type == Card.TypeBasic)
      else
        if use.from == target.id and (use.card.type == Card.TypeTrick or use.card.type == Card.TypeBasic) then
          table.insert(usedCardNames, e.data[1].card.name)
        end
        return false
      end
    end, Player.HistoryPhase) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#wk_heg__liance-invoke::"..target.id, true)
    if #cards == 1 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local usedCardNames = {}
    room:throwCard(self.cost_data, self.name, player, player)
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e)
      local use = e.data[1]
      if table.contains(usedCardNames, e.data[1].card.name) then
        return use.from == target.id and (use.card.type == Card.TypeTrick or use.card.type == Card.TypeBasic)
      else
        if use.from == target.id and (use.card.type == Card.TypeTrick or use.card.type == Card.TypeBasic) then
          table.insert(usedCardNames, e.data[1].card.name)
        end
        return false
      end
    end, Player.HistoryPhase)
    local usedCardTwice = {}
    table.forEach(events, function(e)
      table.insertIfNeed(usedCardTwice, e.data[1].card.name)
    end)

    room:setPlayerMark(target, "wk_heg__liance-phase", usedCardTwice)
    local success, dat = player.room:askForUseActiveSkill(target, "#wk_heg__liance_viewas", "#wk_heg__liance-choose", true)
    if not success then
      H.askCommandTo(player, target, self.name, true)
    else
      local card = Fk.skills["#wk_heg__liance_viewas"]:viewAs(usedCardTwice.cards)
        room:useCard{
        from = target.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
      }
    end
  end,
}

local shilun_active = fk.CreateActiveSkill{
  name = "#wk_heg__shilun_active",
  can_use = Util.FalseFunc,
  target_num = 0,
  card_num = function()
    local cards = Self.player_cards[Player.Hand]
    local suits = {}
    for _, id in ipairs(cards) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        if not table.contains(suits, suit) then
          table.insert(suits, suit)
        end
      end
    end
    return #suits
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip then return end
    return table.every(selected, function (id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
  end,
}

local shilun = fk.CreateTriggerSkill{
  name = "wk_heg__shilun",
  events = {fk.Damaged},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and not player:isKongcheng()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local _, ret = room:askForUseActiveSkill(player, "#wk_heg__shilun_active", "#wk_heg__shilun_active-choose", false)
    local to_remain
    if ret then
      to_remain = ret.cards
    end
    local cards = table.filter(player:getCardIds{Player.Hand}, function (id)
      return not (table.contains(to_remain, id) or player:prohibitDiscard(Fk:getCardById(id)))
    end)
    if #cards > 0 then
      room:throwCard(cards, self.name, player)
    end
    local cards = player.player_cards[Player.Hand]
    if #cards == 4 then
      if #room:canMoveCardInBoard() > 0 then
        local targets = room:askForChooseToMoveCardInBoard(player, "#wk_heg__shilun-move", self.name, true, nil)
        if #targets ~= 0 then
          targets = table.map(targets, function(id) return room:getPlayerById(id) end)
          room:askForMoveCardInBoard(player, targets[1], targets[2], self.name)
        end
      end
    else
      local suits = {Card.Spade, Card.Heart, Card.Diamond, Card.Club}
      for _, id in ipairs(cards) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.removeOne(suits, suit)
        end
      end
      local patternTable = { ["heart"] = {}, ["diamond"] = {}, ["spade"] = {}, ["club"] = {} }
      for _, id in ipairs(room.draw_pile) do
        local card = Fk:getCardById(id)
        if table.contains(suits, card.suit) then
          table.insert(patternTable[card:getSuitString()], id)
        end
      end
      local get = {}
      for _, ids in pairs(patternTable) do
        if #ids > 0 then
          table.insert(get, table.random(ids))
        end
      end
      if #get > 0 then
        room:obtainCard(player, get, false, fk.ReasonPrey)
      end
    end
  end,
}

huanfan:addSkill(liance)
huanfan:addSkill(shilun)
Fk:addSkill(liance_viewas)
Fk:addSkill(shilun_active)
Fk:loadTranslationTable{
  ["wk_heg__huanfan"] = "桓范",
  ["#wk_heg__huanfan"] = "雍国立世",
  ["designer:wk_heg__huanfan"] = "教父",

  ["wk_heg__liance"] = "连策",
  [":wk_heg__liance"] = "其他角色的出牌阶段结束时，若其于此阶段内使用过同名牌，你可弃置一张牌，令其选择是否视为使用此回合内其使用过的其中一张同名牌，若其未以此法使用牌，你对其发起强制执行的“军令”。",
  ["wk_heg__shilun"] = "世论",
  [":wk_heg__shilun"] = "当你受到伤害后，你可展示所有手牌并弃至每种花色各一张，然后若你的手牌：包含四种花色，你可移动场上一张牌；不包含四种花色，你从牌堆中检索并获得手牌中没有的花色牌各一张。",

  ["#wk_heg__liance-invoke"] = "连策：你可以弃置一张牌，令 %dest 视为使用锦囊牌或执行强制“军令”",
  ["#wk_heg__shilun_active-choose"] = "世论：选择花色各不相同的手牌各一张",
  ["#wk_heg__shilun-move"] = "世论：你可以移动场上一张牌",
  ["#wk_heg__liance_viewas"] = "连策",
  ["#wk_heg__shilun_active"] = "世论",

  ["$wk_heg__liance1"] = "将军今出洛阳，恐难再回。",
  ["$wk_heg__liance2"] = "贼示弱于外，必包藏祸心。",
  ["$wk_heg__shilun1"] = "某有良谋，可为将军所用。",
  ["$wk_heg__shilun2"] = "吾负十斗之囊，其盈一石之智。",
  ["~wk_heg__huanfan"] = "有良言而不用，君何愚哉……",
}

local yangyi = General(extension, "wk_heg__yangyi", "shu", 3, 3, General.Male)
local juanxia = fk.CreateTriggerSkill{
  name = "wk_heg__juanxia",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Finish and U.canUseCard(player.room, player, Fk:cloneCard("slash"))
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = {}
    local slash = Fk:cloneCard("slash")
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if not player:isProhibited(p, slash) then
        table.insert(targets, p.id)
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__juanxia-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:useVirtualCard("slash", nil, player, to, self.name, true)
    local choices = {"start_command", "Cancel"}
    if not to.dead and room:askForChoice(to, choices, self.name) == "start_command" and not H.askCommandTo(to, player, self.name) then
      room:damage{
        from = to,
        to = player,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}

--- 交换主副将
---@param room Room
---@param player ServerPlayer
---@return boolean
local function SwapMainAndDeputy(room, player)
  local general1 = player.general
  local general2 = player.deputyGeneral
  if not (general1 and general2) then return false end
  if general1 == "anjiang" then player:revealGeneral(false, true) end
  if general2 == "anjiang" then player:revealGeneral(true, true) end
  general1 = player.general
  general2 = player.deputyGeneral
  if string.find(general1, "lord") 
   or string.find(general1, "zhonghui") or string.find(general1, "simazhao") 
   or string.find(general1, "sunchen") or string.find(general1, "gongsunyuan") 
  then return false end
  room:changeHero(player, "blank_shibing", false, true, false, false, false)
  room:changeHero(player, general2, false, false, true, false, false)
  room:changeHero(player, general1, false, true, true, false, false)
  return true
end

local fenduan = fk.CreateTriggerSkill{
  name = "wk_heg__fenduan",
  anim_type = "offensive",
  relate_to_place = "m",
  events = {"fk.ChooseDoCommand", "fk.AfterCommandUse"},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and target == player and (event == "fk.AfterCommandUse" or not player.chained)
  end,
  on_cost = function (self, event, target, player, data)
    if event == "fk.ChooseDoCommand" then
      return player.room:askForSkillInvoke(player, self.name, nil, "#wk_heg__fenduan-invoke")
    else
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == "fk.ChooseDoCommand" then
      player:setChainState(true)
      return true
    else
      room:askForDiscard(data.from, 2, 2, false, self.name, false)
      SwapMainAndDeputy(room, player)
    end
  end,
}

local choucuo = fk.CreateTriggerSkill{
  name = "wk_heg__choucuo",
  anim_type = "drawcard",
  relate_to_place = "d",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player == target and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wk_heg__choucuo-invoke")
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(2)
    player:showCards(cards)
    if not player.dead then
      local mark = {}
      for _, id in ipairs(cards) do
        if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
          table.insert(mark, id)
          room:setCardMark(Fk:getCardById(id), "@@wk_heg__choucuo_inhand-phase", 1)
        end
      end
      room:setPlayerMark(player, "wk_heg__choucuo-phase", mark)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if type(player:getMark("wk_heg__choucuo-phase")) ~= "table" then return false end
    local mark = player:getMark("wk_heg__choucuo-phase")
    local toLose = {}
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.contains(mark, info.cardId) then
            table.insert(toLose, info.cardId)
          end
        end
      end
    end
    if #toLose > 0 then
      self.cost_data = toLose
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("wk_heg__choucuo-phase")
    table.forEach(self.cost_data, function(id) table.removeOne(mark, id) end)
    player.room:setPlayerMark(player, "wk_heg__choucuo-phase", #mark > 0 and mark or 0)
  end,
}
local choucuo_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__choucuo_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function (self, event, target, player, data)
    return player:usedSkillTimes(choucuo.name, Player.HistoryPhase) > 0 and player.phase == Player.Play and #player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e)
      local use = e.data[1]
      return use.from == player.id
    end, Player.HistoryPhase) >= player.hp
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, choucuo.name, "special")
    player:broadcastSkillInvoke(choucuo.name)
    SwapMainAndDeputy(room, player)
  end,
}
choucuo:addRelatedSkill(choucuo_delay)
local choucuo_prohibit = fk.CreateProhibitSkill{
  name = "#wk_heg__choucuo_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("wk_heg__choucuo-phase") == 0 then return false end
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.find(cards, function(id) return Fk:getCardById(id):getMark("@@wk_heg__choucuo_inhand-phase") == 0 end)
  end,
}
choucuo:addRelatedSkill(choucuo_prohibit)
yangyi:addSkill(juanxia)
yangyi:addSkill(fenduan)
yangyi:addSkill(choucuo)
Fk:loadTranslationTable{
  ["wk_heg__yangyi"] = "杨仪",
  ["#wk_heg__yangyi"] = "狷恙逆跋",
  ["designer:wk_heg__yangyi"] = "教父",

  ["wk_heg__juanxia"] = "狷狭",
  [":wk_heg__juanxia"] = "结束阶段，你可选择一名其他角色，视为对其使用一张【杀】，然后若其存活，其可对你发起“军令”，若你不执行，其对你造成1点伤害。",
  ["wk_heg__fenduan"] = "忿断",
  [":wk_heg__fenduan"] = "主将技，当你选择执行“军令”时，若你未横置，你可改为横置；当你成为“军令”的目标结算完成后，你令此“军令”的发起者弃置两张手牌，然后你交换主副将。",
  ["wk_heg__choucuo"] = "筹措",
  [":wk_heg__choucuo"] = "副将技，出牌阶段开始时，你可摸两张牌并展示之，若如此做，你不能使用其它牌直至你失去这些牌或此阶段结束，且此阶段结束时，若你于此阶段内使用的牌数不小于体力值，你交换主副将。",

  ["#wk_heg__juanxia-choose"] = "狷狭：你可选择一名其他角色，视为对其使用一张【杀】",

  ["#wk_heg__fenduan-invoke"] = "忿断：是否将此次执行的军令改为横置",
  ["#wk_heg__choucuo-invoke"] = "筹措：是否摸两张牌",
  ["#wk_heg__choucuo_delay"] = "筹措",
  ["@@wk_heg__choucuo_inhand-phase"] = "筹措",

  ["$wk_heg__juanxia1"] = "汝有何功，竟能居我之上！",
  ["$wk_heg__juanxia2"] = "恃才傲立，恩怨必偿。",
  ["$wk_heg__fenduan1"] = "北伐之事，丞相亦听我定夺。",
  ["$wk_heg__fenduan2"] = "早知如此，投靠魏国又如何！",
  ["$wk_heg__choucuo1"] = "丞相新丧，吾当继之。",
  ["$wk_heg__choucuo2"] = "规划分部，筹度粮谷。",

  ["~wk_heg__yangyi"] = "魏延庸奴，吾，誓杀汝！",
}

local xuezong = General(extension, "wk_heg__xuezong", "wu", 3)
local dingjian = fk.CreateActiveSkill{
  name = "wk_heg__dingjian",
  anim_type = "offensive",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  card_num = 0,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local get = room:getNCards(1)
    local card_get = Fk:getCardById(get[1])
    player:showCards(get)
    local old_mark = player:getMark("@wk_heg__dingjian-turn")
    if old_mark == 0 then old_mark = {} end
    local choices = {"wk_heg__dingjian_discard", "wk_heg__dingjian_forbidden"}
    if table.contains(old_mark, card_get:getSuitString(true)) or player:getMark("wk_heg__dingjian_forbidden_none-turn") > 0 then
      choices = {"wk_heg__dingjian_discard"}
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "wk_heg__dingjian_forbidden" then
      room:moveCards({
        ids = get,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id
      })
      -- local mark = player:getMark("@wk_heg__dingjian-turn")
      -- if mark == 0 then mark = {} end
      -- table.insertIfNeed(mark, card_get:getSuitString(true))
      -- room:setPlayerMark(player, "@wk_heg__dingjian-turn", mark)
      room:setPlayerMark(player, "wk_heg__dingjian_forbidden_none-turn", 1)
    else
      room:moveCards({
        ids = get,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      local n = (player:getHandcardNum() + 1) // 2
      local cards = room:askForDiscard(player, n, n, false, self.name, false)
      local to_use = {}
      to_use = table.filter(cards, function (id)
        local card = Fk:getCardById(id)
        return room:getCardArea(id) == Card.DiscardPile and not player:prohibitUse(card) and card.suit == card_get.suit
      end)
      local use = U.askForUseRealCard(room, player, to_use, ".", self.name, "#wk_heg__dingjian-use", {expand_pile = to_use, extra_use = true}, true)
      if use then
        room:useCard(use)
      end
    end
  end,
}

-- local dingjian_prohibit = fk.CreateProhibitSkill{
--   name = "#dingjian_prohibit",
--   prohibit_use = function(self, player, card)
--     if player:getMark("@wk_heg__dingjian-turn") == 0 then return false end
--     local subcards = Card:getIdList(card)
--     return #subcards > 0 and table.every(subcards, function(id)
--       return table.contains(player:getCardIds(Player.Hand), id)
--         and table.contains(player:getMark("@wk_heg__dingjian-turn"), Fk:getCardById(id):getSuitString(true))
--     end)
--   end,
-- }

local jiexun = fk.CreateTriggerSkill{
  name = "wk_heg__jiexun",
  events = {fk.TargetSpecifying},
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(self) and H.compareKingdomWith(player, target) and data.firstTarget) then return false end
    if #AimGroup:getAllTargets(data.tos) == 1 and AimGroup:getAllTargets(data.tos)[1] == player.id  then
      return false
    end
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = target:drawCards(1, self.name)
    target:showCards(card)
    local targets = AimGroup:getAllTargets(data.tos)
    local tos = #targets == 1 and targets or room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__jiexun-choose-cancel:::" .. data.card:toLogString(), self.name, false)
    AimGroup:cancelTarget(data, tos[1])
    if Fk:getCardById(card[1]).suit == data.card.suit then
      local mark = target:getTableMark("@wk_heg__jiexun-turn")
      if table.insertIfNeed(mark, Fk:getCardById(card[1]):getSuitString(true)) then
        room:setPlayerMark(target, "@wk_heg__jiexun-turn", mark)
        mark = target:getTableMark("_wk_heg__jiexun-turn")
        mark[Fk:getCardById(card[1]):getSuitString(true)] = player.id
        room:setPlayerMark(target, "_wk_heg__jiexun-turn", mark)
      end
    end
  end,
}

local jiexun_trigger = fk.CreateTriggerSkill{
  name = "#wk_heg__jiexun_trigger",
  events = {fk.AfterCardTargetDeclared},
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    if target:getMark("@wk_heg__jiexun-turn") == 0 then return false end
    return target:getTableMark("_wk_heg__jiexun-turn")[data.card:getSuitString(true)] == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = room:getUseExtraTargets(data)
    local to = room:askForChoosePlayers(target, targets, 1, 1, "#wk_heg__jiexun-choose-add:::" .. data.card:toLogString(), self.name, true)
    if #to > 0 then TargetGroup:pushTargets(data.tos, to[1]) end
    local mark = target:getTableMark("@wk_heg__jiexun-turn")
    table.removeOne(mark, data.card:getSuitString(true))
    if #mark == 0 then mark = 0 end
    room:setPlayerMark(target, "@wk_heg__jiexun-turn", mark)
    mark = target:getTableMark("_wk_heg__jiexun-turn")
    mark[data.card:getSuitString(true)] = nil
    room:setPlayerMark(target, "_wk_heg__jiexun-turn", mark)
  end,
}

-- dingjian:addRelatedSkill(dingjian_prohibit)
xuezong:addSkill(dingjian)

jiexun:addRelatedSkill(jiexun_trigger)
xuezong:addSkill(jiexun)
Fk:loadTranslationTable{
  ["wk_heg__xuezong"] = "薛综",
  ["designer:wk_heg__xuezong"] = "教父",
  ["wk_heg__dingjian"] = "定谏",
  [":wk_heg__dingjian"] = "出牌阶段，你可展示牌堆顶一张牌并选择一项：1.弃置半数手牌（向上取整），然后使用其中一张与展示牌花色相同的牌；2.获得此牌，然后你本回合不能选择此项。",
  ["wk_heg__jiexun"] = "诫训",
  [":wk_heg__jiexun"] = "与你势力相同角色使用牌指定其以外的角色为目标时，你可令其摸一张牌并展示之并取消此牌一个目标，若两牌花色相同，其本回合下次使用此花色的牌选择目标后，其可以额外指定一个目标。",

  ["#wk_heg__dingjian-use"] = "定谏：你可以使用其中一张牌",
  ["#wk_heg__jiexun-choose-add"] = "诫训：你可以为 %arg 额外指定一个合法目标",
  ["#wk_heg__jiexun-choose-cancel"] = "诫训：请为 %arg 取消一个目标",
  ["@wk_heg__jiexun-turn"] = "诫训",
  ["@wk_heg__dingjian-turn"] = "定谏",
  ["#wk_heg__jiexun_trigger"] = "诫训",
  ["dingjian"] = "定谏",

  ["wk_heg__dingjian_discard"] = "弃牌，使用其中一张",
  ["wk_heg__dingjian_forbidden"] = "获得牌，不能再选择此项",

  ["$wk_heg__dingjian1"] = "礼尚往来，乃君子风范。",
  ["$wk_heg__dingjian2"] = "以子之矛，攻子之盾。",
  ["$wk_heg__jiexun1"] = "帝王应以社稷为重，以大观为主。",
  ["$wk_heg__jiexun2"] = "吾冒昧进谏，只求陛下思虑。",
  ["~wk_heg__xuezong"] = "尔等竟做如此有辱斯文之事。",
}

local kuaizi = General(extension, "wk_heg__kuaizi", "qun", 3, 3, General.Male)
local zongpo = fk.CreateTriggerSkill{
  name = "wk_heg__zongpo",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function (p)
      return not H.compareKingdomWith(player, p)
    end), Util.IdMapper)
    local tos, id = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".|.|.|.|.|basic", "#wk_heg__zongpo-choose", self.name, true)
    if #tos ~= 0 then
      self.cost_data = {tos, id}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos = self.cost_data[1]
    local to = room:getPlayerById(tos[1])
    room:obtainCard(tos[1], self.cost_data[2], false, fk.ReasonGive)

    local mark = {}
    table.insert(mark, self.cost_data[2])
    room:setCardMark(Fk:getCardById(self.cost_data[2]), "@@alliance-inhand", 1)
    room:setPlayerMark(to, "wk_heg__zongpo", mark)

    if player.dead or to.dead then return false end
    local choices = {"wk_heg__zongpo_giveback:".. player.id, "Cancel"}
    local choice = room:askForChoice(to, choices, self.name)
    local card_ids = Card:getIdList(data.card)
    if #card_ids == 0 or choice == "Cancel" then return false end
    if data.card.type == Card.TypeEquip then
      if not table.every(card_ids, function (id)
        return room:getCardArea(id) == Card.PlayerEquip and room:getCardOwner(id) == player
      end) then return false end
    else
      if not table.every(card_ids, function (id)
        return room:getCardArea(id) == Card.Processing
      end) then return false end
    end
    room:moveCardTo(card_ids, Player.Hand, player, fk.ReasonPrey, self.name, nil, false, player.id)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    local toLose = {}
    for _, move in ipairs(data) do
      if not move.from then return false end
      local to = room:getPlayerById(move.from)
      if to.dead or type(to:getMark("wk_heg__zongpo")) ~= "table" then return false end
      local mark = to:getMark("wk_heg__zongpo")
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand and table.contains(mark, info.cardId) then
          table.insert(toLose, info.cardId)
        end
      end
    end
    if #toLose > 0 then
      self.cost_data = toLose
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      local to = room:getPlayerById(move.from)
      local mark = to:getMark("wk_heg__zongpo")
      table.forEach(self.cost_data, function(id) table.removeOne(mark, id) end)
      table.forEach(self.cost_data, function(id) player.room:setCardMark(Fk:getCardById(id), "@@alliance-inhand", 0) end)
      player.room:setPlayerMark(to, "wk_heg__zongpo", #mark > 0 and mark or 0)
    end
  end,
}

local shenshi = fk.CreateTriggerSkill{
  name = "wk_heg__shenshi",
  anim_type = "defensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if not player:hasSkill(self) then return false end
    for _, move in ipairs(data) do
      if move.from and move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            self.cost_data = move.to
            local from = room:getPlayerById(move.from)
            local to = room:getPlayerById(move.to)
            return not H.compareKingdomWith(from, to)
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    to:drawCards(1, self.name)
    room:setPlayerMark(to, "wk_heg__shenshi_draw-turn", 1)
  end,

  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    return data.from and data.from:getMark("wk_heg__shenshi_draw-turn") > 0 and H.compareKingdomWith(data.to, player)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "wk_heg__shenshi_damage-turn", 1)
  end,
}

local shenshi_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__shenshi_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function (self, event, target, player, data)
    return player:usedSkillTimes(shenshi.name, Player.HistoryTurn) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("wk_heg__shenshi_damage-turn") == 0 then
      local targets = table.map(table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end), Util.IdMapper)
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,
}
shenshi:addRelatedSkill(shenshi_delay)
kuaizi:addSkill(zongpo)
kuaizi:addSkill(shenshi)

Fk:loadTranslationTable{
  ["wk_heg__kuaizi"] = "蒯越蒯良",
  ["#wk_heg__kuaizi"] = "雍论臼谋",
  ["designer:wk_heg__kuaizi"] = "教父&风箫",

  ["wk_heg__zongpo"] = "纵迫",
  [":wk_heg__zongpo"] = "每回合限一次，当你使用牌结算后，你可交给一名与你势力不同的角色一张基本牌，此牌于其手牌区内视为拥有“合纵”标记，然后其可令你获得你使用的牌。",
  ["wk_heg__shenshi"] = "审时",
  [":wk_heg__shenshi"] = "与你势力不同的角色获得你的牌后，你可令其摸一张牌，若如此做，此回合结束时，若此回合内所有以此法摸牌的角色于以此法摸牌后未对与你势力相同的角色造成过伤害，与你势力相同的角色各摸一张牌。",

  ["#wk_heg__zongpo-choose"] = "纵迫：你可以交给一名其他角色一张基本牌",
  ["wk_heg__zongpo_giveback"] = "令 %src 获得其使用的牌",

  ["#wk_heg__shenshi_delay"] = "审时",

  ["$wk_heg__zongpo1"] = "得遇曹公，吾之幸也。",
  ["$wk_heg__zongpo2"] = "曹公得荆不喜，喜得吾二人足以。",
  ["$wk_heg__shenshi1"] = "深中足智，鉴时审情。",
  ["$wk_heg__shenshi2"] = "数语之言，审时度势。",
  ["~wk_heg__kuaizi"] = "表不能善用，所憾也",
}

local caorui = General(extension, "wk_heg__caorui", "wei", 3, 3, General.Male)
local yuchen = fk.CreateTriggerSkill{
  name = "wk_heg__yuchen",
  events = {fk.EventPhaseStart},
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(self) and target ~= player and target.phase == Player.Finish and #player:getCardIds("he") > 1) then return false end
    return #player.room.logic:getActualDamageEvents(1, function(e)
      return e.data[1].from == target
    end, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local cards = player.room:askForCard(player, 2, 2, true, self.name, true, ".", "#wk_heg__yuchen-give")
    if #cards == 2 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:obtainCard(target, self.cost_data, false, fk.ReasonGive)
    if not target.dead then
      room:setPlayerMark(target, "@@wk_heg__yuchen-turn", 1)
      target:gainAnExtraPhase(Player.Play)
    end
  end
}

local yuchen_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__yuchen_delay",
  events = {fk.EventPhaseEnd},
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if not (target:getMark("@@wk_heg__yuchen-turn") > 0 and target.phase == Player.Play and player:usedSkillTimes(yuchen.name, Player.HistoryTurn) > 0 and player:isAlive()) then return false end
    return #player.room.logic:getActualDamageEvents(1, function(e)
      return e.data[1].from == target
    end, Player.HistoryPhase) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}

local mingsong = fk.CreateTriggerSkill{
  name = "wk_heg__mingsong",
  events = {fk.DamageCaused},
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and target and H.compareKingdomWith(player, target) and #target:getCardIds("e") > 0
      and table.find(player.room.alive_players, function(p) return target:canMoveCardsInBoardTo(p, "e") end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function (p)
      return target:canMoveCardsInBoardTo(p, "e")
    end), Util.IdMapper)
    targets = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__mingsong-ask::"..target.id, self.name, true)
    if #targets > 0 then
      self.cost_data = targets[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:askForMoveCardInBoard(player, target, to, self.name, "e", target)
    local targets = {}
    local num = 999
    for _, p in ipairs(room.alive_players) do
      local n = p.hp
      if n <= num then
        if n < num then
          num = n
          targets = {}
        end
        if n < p.maxHp then
          table.insert(targets, p.id)
        end
      end
    end
    if #targets > 0 then
      local to_heal = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__mingsong-choose", self.name, true)
      if #to_heal > 0 then
        room:recover{
          who = room:getPlayerById(to_heal[1]),
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    end
    return true
  end,
}

caorui:addSkill(yuchen)
yuchen:addRelatedSkill(yuchen_delay)
caorui:addSkill(mingsong)
Fk:loadTranslationTable{
  ["wk_heg__caorui"] = "曹叡",
  ["designer:wk_heg__caorui"] = "小曹神",
  ["wk_heg__yuchen"] = "驭臣",
  [":wk_heg__yuchen"] = "其他角色的结束阶段，若其本回合未造成过伤害，你可以交给其两张牌，令其执行一个额外的出牌阶段，若如此做，此额外的阶段结束时，若其于此阶段未造成过伤害，你对其造成1点伤害。",
  ["wk_heg__mingsong"] = "明讼",
  [":wk_heg__mingsong"] = "与你势力相同的角色造成伤害时，你可以移动其装备区里的一张牌，防止此伤害，然后你可令一名体力值最小的角色回复1点体力。",

  ["@@wk_heg__yuchen-turn"] = "驭臣",
  ["#wk_heg__yuchen_delay"] = "驭臣",

  ["#wk_heg__yuchen-give"] = "驭臣：你可交给其两张牌，令其执行一个额外的出牌阶段",
  ["#wk_heg__mingsong-ask"] = "明讼：你可选择一名角色，将 %dest 装备区内的一张牌移动至其装备区内，<br />防止此伤害并令一名体力值最小的角色回复1点体力",
  ["#wk_heg__mingsong-choose"] = "明讼：你可令一名体力值最小的角色回复1点体力",

  ["$wk_heg__yuchen1"] = "大展宏图，就在今日。",
  ["$wk_heg__yuchen2"] = "复我大魏，扬我国威。",
  ["$wk_heg__mingsong1"] = "你我推心置腹，岂能相负。",
  ["$wk_heg__mingsong2"] = "孰忠孰奸，朕尚能明辨。",

  ["~wk_heg__caorui"] = "悔不该耽于逸乐，至由今日。",
}

local hudu = General(extension, "wk_heg__hudu", "shu", 4, 4, General.Male)
local fuman = fk.CreateActiveSkill{
  name = "wk_heg__fuman",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#wk_heg__fuman",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if player.dead or not table.contains(player:getCardIds("h"), effect.cards[1]) then return end
    local card = Fk:getCardById(effect.cards[1])
    player:showCards(card)
    room:obtainCard(target, card, true, fk.ReasonGive)
    if player.dead or target.dead then return end
    local cards2 = target:getCardIds("he")
    local choices = {}
    if #cards2 > 1 then
      local num = #table.filter(target:getCardIds("he"), function(id) return Fk:getCardById(id).color == card.color end)
      if num > 1 then
        table.insert(choices, "wk_heg__fuman-give")
      end
    end
    local slash_card = Fk:cloneCard("slash")
    slash_card.skillName = self.name
    if target:canUseTo(slash_card, player, { bypass_times = true, bypass_distances = true }) and not target:prohibitUse(slash_card) then
      table.insert(choices, "wk_heg__fuman-useslash")
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(target, choices, self.name)
    if choice == "wk_heg__fuman-useslash" then
      local use = room:useVirtualCard("slash", nil, target, player, self.name, true)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    else
      local cards3 
      if card.color == Card.Red then
        cards3 = room:askForCard(target, 2, 2, true, self.name, false, ".|.|heart,diamond|.|.|.", "#wk_heg__fuman-give1:"..player.id)
      elseif card.color == Card.Black then
        cards3 = room:askForCard(target, 2, 2, true, self.name, false, ".|.|club,spade|.|.|.", "#wk_heg__fuman-give2:"..player.id)
      end
      room:moveCardTo(cards3, Player.Hand, player, fk.ReasonGive, self.name, nil, false, player.id)
    end
  end, 
}

local fuwei = fk.CreateTriggerSkill{
  name = "wk_heg__fuwei",
  anim_type = "support",
  events = {"fk.GeneralRemoving", fk.EnterDying},
  can_trigger = function (self, event, target, player, data)
    if event == fk.EnterDying then 
      return player:hasSkill(self) and H.compareKingdomWith(player, target)
      and #table.filter(target.player_skills, function(s)
        return s.frequency == Skill.Limited and target:usedSkillTimes(s.name, Player.HistoryGame) > 0
      end) > 0
    else
      return player:hasSkill(self) and H.compareKingdomWith(player, target)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == "fk.GeneralRemoving" then
      H.transformGeneral(room, target, not data)
      return true
    else
      local skillNames = table.map(table.filter(target.player_skills, function(s)
        return s.frequency == Skill.Limited and target:usedSkillTimes(s.name, Player.HistoryGame) > 0
      end), Util.NameMapper)
      local skill = room:askForChoice(player, skillNames, self.name, "#wk_heg__fuwei-reset::"..target.id)
      target:addSkillUseHistory(skill, -1)
      player:throwAllCards("h")
      room:handleAddLoseSkills(player, "-wk_heg__fuwei", nil)
    end
  end,
}

hudu:addSkill(fuman)
hudu:addSkill(fuwei)
Fk:loadTranslationTable{
  ["wk_heg__hudu"] = "狐笃",
  ["designer:wk_heg__hudu"] = "二四",

  ["wk_heg__fuman"] = "抚蛮",
  [":wk_heg__fuman"] = "出牌阶段限一次，你可展示并交给一名其他角色一张手牌，然后其选择一项：1.交给你两张与此牌颜色相同的牌；2.视为对你使用一张【杀】，然后你对其造成1点伤害。",
  ["wk_heg__fuwei"] = "扶危",
  [":wk_heg__fuwei"] = "与你势力相同的角色：1.移除武将牌时，你可令此次移除操作改为变更对应的武将牌；2.进入濒死状态时，你可令其武将牌上一个已发动过的限定技的发动次数+1，然后你弃置所有手牌并失去此技能。",

  ["#wk_heg__fuman"] = "抚蛮：交给一名其他角色一张牌",

  ["wk_heg__fuman-give"] = "交给牌",
  ["wk_heg__fuman-useslash"] = "视为使用【杀】",
  ["#wk_heg__fuman-give1"] = "交给 %src 两张红色牌",
  ["#wk_heg__fuman-give2"] = "交给 %src 两张黑色牌",
  ["#wk_heg__fuwei-reset"] = "扶危：选择 %src 一个已发动过的限定技，令此技能视为未发动过",
  ["#wk_heg__fuman_trigger"] = "抚蛮",

  ["$wk_heg__fuman1"] = "国家兴亡，匹夫有责。",
  ["$wk_heg__fuman2"] = "跟着我们丞相走，错不了。",
  ["$wk_heg__fuwei1"] = "",
  ["$wk_heg__fuwei2"] = "",
  ["~wk_heg__hudu"] = "南征不定，后患无穷…",
}

local zhuran = General(extension, "wk_heg__zhuran", "wu", 4, 4, General.Male)
local danshou = fk.CreateTriggerSkill{
  name = "wk_heg__danshou",
  events = {fk.TargetConfirmed},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player and data.from ~= player.id and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return table.contains(TargetGroup:getRealTargets(use.tos), player.id)
      end, Player.HistoryTurn)
      self.cost_data = #events
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:getHandcardNum() - self.cost_data
    if n > 0 then
      local cards = player.room:askForDiscard(player, n, n, false, self.name, true, ".", "#wk_heg__danshou-damage::"..data.from..":"..n, true)
      if #cards == n then
        self.cost_data = {n, cards}
        return true
      end
    else
      self.cost_data = {n}
      return player.room:askForSkillInvoke(player, self.name, nil, "#wk_heg__danshou:::"..-n)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[1] > 0 then
      local to = room:getPlayerById(data.from)
      room:doIndicate(player.id, {data.from})
      room:throwCard(self.cost_data[2], self.name, player, player)
      if not to.dead then 
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = self.name,
        }
      end
    else
      player:drawCards(-self.cost_data[1], self.name)
    end
  end,
}

zhuran:addCompanions("hs__lvmeng")
zhuran:addSkill(danshou)
Fk:loadTranslationTable{
  ["wk_heg__zhuran"] = "朱然",
  ["#wk_heg__zhuran"] = "胆略无双",
  ["designer:wk_heg__zhuran"] = "教父&二四",

  ["wk_heg__danshou"] = "胆守",
  [":wk_heg__danshou"] = "每回合限一次，当你成为其他角色使用牌的目标后，你可将手牌调整至X张，若你因此法失去牌，你对其造成1点伤害（X为你本回合成为过牌目标的次数）。",

  ["#wk_heg__danshou-damage"] = "胆守：你可以弃置 %arg 张牌，对 %dest 造成1点伤害",
  ["#wk_heg__danshou"] = "胆守：你可以摸 %arg 张牌",

  ["$wk_heg__danshou1"] = "到此为止了！",
  ["$wk_heg__danshou2"] = "以胆为守，扼敌咽喉！",
  ["~wk_heg__zhuran"] = "何人竟有如此之胆！？",
}

local guanning = General(extension, "wk_heg__guanning", "qun", 3, 3, General.Male)
local duanyi = fk.CreateTriggerSkill{
  name = "wk_heg__duanyi",
  events = {fk.GeneralRevealed},
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, v in pairs(data) do
        -- 先这样，藕合过于麻烦
        if table.contains(Fk.generals[v]:getSkillNameList(), self.name)
          or (player:getMark("wk_heg__duanyi") ~= 0 and target ~= player and not target.dead
          and not ((player:getMark("wk_heg__duanyi") == 9 and target.phase == 9) or (player:getMark("wk_heg__duanyi") ~= 9 and target.phase ~= 9))) then 
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("wk_heg__duanyi") == 0 then
      player:drawCards(2, self.name)
      player.room:setPlayerMark(player, "wk_heg__duanyi", player.phase)
    else
      local choices = {"wk_heg__duanyi_discard::"..target.id, "Cancel"}
      local choice = room:askForChoice(player, choices, self.name)
      if choice ~= "Cancel" then
        room:askForDiscard(target, 2, 2, true, self.name, false)
      end
    end
  end,
}

---@param object Card|Player
---@param markname string
---@param suffixes string[]
---@return boolean
local function hasMark(object, markname, suffixes)
  if not object then return false end
  for mark, _ in pairs(object.mark) do
    if mark == markname then return true end
    if mark:startsWith(markname .. "-") then
      for _, suffix in ipairs(suffixes) do
        if mark:find(suffix, 1, true) then return true end
      end
    end
  end
  return false
end

local gaojie = fk.CreateTriggerSkill{
  name = "wk_heg__gaojie",
  events = {fk.TargetConfirming, fk.AfterCardsMove},
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.TargetConfirming then
      return target == player and data.card and data.card:isCommonTrick() and data.card.package.name == "strategic_advantage"
    else
      local cardInfo = {}
      for _, move in ipairs(data) do
        if move.to and move.to == player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if hasMark(Fk:getCardById(info.cardId), "@@alliance", MarkEnum.CardTempMarkSuffix) then
              table.insert(cardInfo, info.cardId)
            end
          end
        end
      end
      if #cardInfo > 0 then
        self.cost_data = cardInfo
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    if event == fk.TargetConfirming then
      AimGroup:cancelTarget(data, player.id)
      return true
    else
      if #self.cost_data > 0 then
        player.room:throwCard(self.cost_data, self.name, player, player)
        if player:isWounded() and not player.dead then
          player.room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          })
        end
      end
    end
  end,
}

guanning:addSkill(duanyi)
guanning:addSkill(gaojie)
Fk:loadTranslationTable{
  ["wk_heg__guanning"] = "管宁",
  ["designer:wk_heg__guanning"] = "教父&朱古力",
  ["wk_heg__duanyi"] = "断义",
  [":wk_heg__duanyi"] = "当你首次明置此武将牌后，你摸两张牌，且其他角色明置武将牌后，若其明置武将牌的方式与你首次明置武将牌的方式不同，你可令其弃置两张牌。<br />"..
  "<font color = 'gray'>注：明置武将牌的方式，分为“回合开始时亮将”和“因技能亮将”两种形式。</font>",
  ["wk_heg__gaojie"] = "高节",
  [":wk_heg__gaojie"] = "锁定技，当你成为势备篇锦囊牌的目标时，取消之；当你获得带有“合纵”标记的牌后，你弃置之，然后回复1点体力。<br />"..
  "<font color = 'gray'>注：势备篇锦囊牌包括【勠力同心】【联军盛宴】【挟天子以令诸侯】【敕令】【调虎离山】【水淹七军】【火烧连营】。</font>",

  ["wk_heg__duanyi_discard"] = "令 %dest 弃置两张牌",

  ["$wk_heg__duanyi1"] = "",
  ["$wk_heg__duanyi2"] = "",
  ["$wk_heg__gaojie1"] = "失路青山隐，藏名白水游。",
  ["$wk_heg__gaojie2"] = "隐居青松畔，遁走孤竹丘。",

  ["~wk_heg__guanning"] = "高节始终，无憾矣…",
}

local chengyu = General(extension, "wk_heg__chengyu", "wei", 3)
local shefu = fk.CreateTriggerSkill{
  name = "wk_heg__shefu",
  anim_type = "special",
  events = {fk.Damaged},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and player == target and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local chooses = table.map(table.filter(room.alive_players, function (p)
      return p ~= room.current
    end), Util.IdMapper)
    local tos, id = room:askForChooseCardAndPlayers(player, chooses, 1, 2, ".", "#wk_heg__shefu-choose", self.name, true)
    if #tos ~= 0 then
      self.cost_data = {tos, id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = self.cost_data[1]
    local id = self.cost_data[2]
    room:throwCard({id}, self.name, player, player)
    for i = 1, #to, 1 do
      local too = room:getPlayerById(to[i])
      room:setPlayerMark(too, "@@lure_tiger-turn", 1)
      room:setPlayerMark(too, MarkEnum.PlayerRemoved .. "-turn", 1)
      room:handleAddLoseSkills(too, "#lure_tiger_hp|#lure_tiger_prohibit", nil, false, true) -- global…
      room.logic:trigger("fk.RemoveStateChanged", too, nil) -- FIXME
    end
    local targets = table.map(table.filter(room.alive_players, function (p)
      return H.inSiegeRelation(p:getLastAlive(), p:getNextAlive(), p)
    end), Util.IdMapper)
    local damage_to_id = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__shefu-choose-damage", self.name, true)
    local damage_to = room:getPlayerById(damage_to_id[1])
    if not player.dead and not damage_to.dead then
      room:damage{
        from = player,
        to = damage_to,
        damage = 1,
        skillName = self.name
      }
    end
  end,
}


local danli = fk.CreateTriggerSkill{
  name = "wk_heg__danli",
  events = {fk.EventPhaseStart},
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Finish and player == target and H.hasGeneral(player, true)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    H.removeGeneral(room, player, true)
    H.addHegMark(room, player, "companion")
    local kingdom = H.getKingdom(player)
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.kingdom == "unknown" and not p.dead then
        if H.getKingdomPlayersNum(room)[kingdom] >= #room.players // 2 and not table.find(room.alive_players, function(_p) return _p.general == "ld__lordcaocao" end) then break end
        local main, deputy = false, false
        if H.compareExpectedKingdomWith(p, player) then
          local general = Fk.generals[p:getMark("__heg_general")]
          main = general.kingdom == kingdom or general.subkingdom == kingdom
          general = Fk.generals[p:getMark("__heg_deputy")]
          deputy = general.kingdom == kingdom or general.subkingdom == kingdom
        end
        H.askForRevealGenerals(room, p, self.name, main, deputy)
      end
    end
    local targets = table.map(table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) and p ~= player end), Util.IdMapper)
    if #targets > 0 then
      room:doIndicate(player.id, targets)
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if not p.dead and H.hasGeneral(p, true) then
          local choices = {"wk_heg__danli_remove", "Cancel"}
          local choice = room:askForChoice(p, choices, self.name)
          if choice ~= "Cancel" then
            H.removeGeneral(room, p, true)
            H.addHegMark(room, p, "companion")
          end
        end
      end
    end
  end,
}

chengyu:addSkill(shefu)
chengyu:addSkill(danli)
Fk:loadTranslationTable{
  ["wk_heg__chengyu"] = "程昱",
  ["designer:wk_heg__chengyu"] = "朱古力",
  ["wk_heg__shefu"] = "设伏",
  [":wk_heg__shefu"] = "当你受到伤害后，你可调离至多两名非当前回合角色，然后你可对一名被围攻的角色造成1点伤害。",
  ["wk_heg__danli"] = "胆戾",
  [":wk_heg__danli"] = "结束阶段，你可移除副将并获得一个“珠联璧合”标记，然后你发起势力召唤，且与你势力相同的角色可依次移除副将并获得一个“珠联璧合”标记。",

  ["#wk_heg__shefu-choose"] = "设伏：你可弃置一张牌，调离至多两名非当前回合角色",
  ["#wk_heg__shefu-choose-damage"] = "设伏：你可对一名被围攻的角色造成1点伤害",
  ["wk_heg__danli_remove"] = "移除副将并获得一个“珠联璧合”标记",

  ["#wk_heg__shefu_viewas"] = "设伏",

  ["$wk_heg__shefu1"] = "圈套已设，埋伏已完，只等敌军进来。",
  ["$wk_heg__shefu2"] = "如此天网，谅你插翅也难逃。",
  ["$wk_heg__danli1"] = "曹公智略乃上天所授。",
  ["$wk_heg__danli2"] = "天下大乱，群雄并起，必有命世。",

  ["~wk_heg__chengyu"] = "此诚报效国家之时，吾却休矣…",
}
local luji = General(extension, "wk_heg__luji", "wu", 3, 3, General.Male)
local huaiju = fk.CreateTriggerSkill{
  name = "wk_heg__huaiju",
  events = {fk.CardUseFinished},
  anim_type = "special",
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(self) and not H.compareKingdomWith(player, target) and data.tos and
    table.find(TargetGroup:getRealTargets(data.tos), function(id) return id == player.id end)) then return false end
    return not data.card.is_damage_card and table.every(Card:getIdList(data.card), function (id) return player.room:getCardArea(id) == Card.Processing end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return p ~= target end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__huaiju_choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card_ids = Card:getIdList(data.card)
    if #card_ids == 0 then return false end
    room:moveCardTo(card_ids, Player.Hand, room:getPlayerById(self.cost_data), fk.ReasonPrey, self.name, nil, true, player.id)
    local choices = {"Cancel"}
    if player:isAlive() and #player:getCardIds("he") > 0 then
      table.insert(choices, "#wk_heg__huaiju_discard_choose::" .. player.id)
    end
    local choice = room:askForChoice(target, choices, self.name)
    if choice ~= "Cancel" then
      local cid = room:askForCardChosen(target, player, "he", self.name)
      room:throwCard({cid}, self.name, player, target)
    end
  end,
}

local zhenglun = fk.CreateTriggerSkill{
  name = "wk_heg__zhenglun",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    player:showCards(player:getCardIds(Player.Hand))
    while true do
      local cards = player.player_cards[Player.Hand]
      -- player:showCards(cards)
      local suits = {}
      for _, id in ipairs(cards) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
      end
      if player:getHandcardNum() > #room.alive_players or #suits == 4 then
        room:delay(1000)
        player:showCards(cards) -- 睿智
        break
      else
        room:delay(500)
        player:drawCards(1, self.name)
      end
    end
    local suitMapper = { [1] = {}, [2] = {}, [3] = {}, [4] = {} }
    table.forEach(player:getCardIds(Player.Hand), function(id)
      if Fk:getCardById(id).suit ~= Card.NoSuit then
        table.insert(suitMapper[Fk:getCardById(id).suit], id)
      end
    end)
    local maxNum = -1
    local all_suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local choices = {}
    for i, j in ipairs(suitMapper) do
      local num = #j
      if num >= maxNum then
        if num > maxNum then
          maxNum = num
          choices = {}
        end
        table.insert(choices, all_suits[i])
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#wk_heg__zhenglun-discard")
    local cid = suitMapper[table.indexOf(all_suits, choice)]
    room:throwCard(cid, self.name, player, player)
  end,
}

luji:addSkill(huaiju)
luji:addSkill(zhenglun)
Fk:loadTranslationTable{
  ["wk_heg__luji"] = "陆绩",
  ["designer:wk_heg__luji"] = "静谦",
  ["wk_heg__huaiju"] = "怀橘",
  [":wk_heg__huaiju"] = "其他势力角色的指定你为目标的非伤害牌结算后，你可令一名除使用者以外的角色获得此牌，然后使用者可以弃置你的一张牌。",
  ["wk_heg__zhenglun"] = "整论",
  [":wk_heg__zhenglun"] = "结束阶段，你可摸一张牌，然后若你手牌数大于存活角色数或其中包含四种花色，则你展示所有手牌并弃置手牌中数量最多的一种花色的所有牌，否则你重复此流程。",

  ["#wk_heg__huaiju_choose"] = "怀橘：你可以将此牌交给一名除使用者外的角色",
  ["#wk_heg__huaiju_discard_choose"] = "弃置 %dest 的一张牌",
  ["#wk_heg__zhenglun-discard"] = "整论：弃置手牌中数量最多的一种花色的所有牌",

  ["$wk_heg__huaiju1"] = "情深舐犊，怀拙藏橘。",
  ["$wk_heg__huaiju2"] = "袖中怀绿橘，遗母报乳哺。",
  ["$wk_heg__zhenglun1"] = "遗失礼仪，则具非议。",
  ["$wk_heg__zhenglun2"] = "行遗礼之举，于不敬王者。",

  ["~wk_heg__luji"] = "恨不能见，车同轨，书同文…",
}

local wangyun = General(extension, "wk_heg__wangyun", "qun", 4)
wangyun.mainMaxHpAdjustedValue = -1

local jingong = fk.CreateTriggerSkill{
  name = "wk_heg__jingong",
  anim_type = "drawcard",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self) and player.phase == Player.Finish) then return false end
    self.cost_data = {}
    return #player.room.logic:getActualDamageEvents(2, function(e)
      if e.data[1].from == player then
        return table.insertIfNeed(self.cost_data, e.data[1].to)
      end
      return false
    end, Player.HistoryTurn) > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if #self.cost_data == 1 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(2, self.name)
    else
      room:notifySkillInvoked(player, self.name, "negative")
      room:loseHp(player, 1, self.name)
    end
  end,
}

local mingjie = fk.CreateTriggerSkill{
  name = "wk_heg__mingjie",
  relate_to_place = 'm',
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__mingjie-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:addTableMark(to, "@@wk_heg__mingjie-turn", player.id)
  end,
}

local lianji = fk.CreateTriggerSkill{
  name = "wk_heg__lianji",
  anim_type = "special",
  events = {fk.TargetSpecifying},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.card.type == Card.TypeTrick
      and data.tos and #AimGroup:getAllTargets(data.tos) == 1
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = AimGroup:getAllTargets(data.tos)
    local tos = #targets == 1 and targets or room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__lianji-choose:::" .. data.card:toLogString(), self.name, false)
    AimGroup:cancelTarget(data, tos[1])
    local to = room:getPlayerById(tos[1])
    if to:getMark("wk_heg__lianji_must-turn") ~= 0 then
      H.askCommandTo(player, to, self.name, true)
    else
      if not H.askCommandTo(player, to, self.name) then
        room:setPlayerMark(to, "wk_heg__lianji_must-turn", 1)
      end
    end
  end,
}

local mingjie_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__mingjie_delay",
  mute = true,
  events = {fk.AfterCardTargetDeclared, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      if target == player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
        local mark
        local targets = table.filter(room:getUseExtraTargets(data), function (id)
          mark = room:getPlayerById(id):getMark("@@wk_heg__mingjie-turn")
          return type(mark) == "table" and table.contains(mark, player.id)
        end)
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      end
    elseif event == fk.DamageCaused then
      local mark = data.to:getMark("@@wk_heg__mingjie-turn")
      return player == target and type(mark) == "table" and table.contains(mark, player.id)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      local tos = room:askForChoosePlayers(player, self.cost_data, 1, #self.cost_data,
        "#mingjiew-choose:::"..data.card:toLogString(), "mingjiew", true)
      if #tos > 0 then
        table.forEach(tos, function (id)
          table.insert(data.tos, {id})
        end)
      end
    else
      return true
    end
  end,
}

wangyun:addSkill(jingong)
wangyun:addSkill(lianji)
wangyun:addSkill(mingjie)
mingjie:addRelatedSkill(mingjie_delay)
Fk:loadTranslationTable{
  ["wk_heg__wangyun"] = "王允",
  ["designer:wk_heg__wangyun"] = "教父&静谦&朱古力",
  ["wk_heg__jingong"] = "矜功",
  [":wk_heg__jingong"] = "锁定技，结束阶段，若本回合受到你造成伤害的角色数：为1，你摸两张牌；大于1，你失去1点体力。",
  ["wk_heg__lianji"] = "连计",
  [":wk_heg__lianji"] = "当你使用普通锦囊牌指定唯一目标时，你可取消之，对其发起“军令”，若其不执行，直至本回合结束，你以此法对其发起的“军令”改为强制执行。",
  ["wk_heg__mingjie"] = "铭戒",
  [":wk_heg__mingjie"] = "主将技，此武将牌上单独的阴阳鱼个数-1；出牌阶段开始时，你可选择一名其他角色，你于本回合内：1.使用牌可以额外指定其为目标；2.防止对其造成的伤害。",

  ["#wk_heg__lianji-choose"] = "连计：你可以取消 %arg 的唯一目标且对其发起“军令”",

  ["@@wk_heg__mingjie-turn"] = "铭戒",
  ["@@wk_heg__lianji_must-turn"] = "连计 强制军令",

  ["#wk_heg__mingjie-choose"] = "铭戒：你可以选择一名其他角色，防止本回合对其造成的伤害且本回合使用牌可以额外指定其为目标",

  -- ["#wk_heg__lianji0-active"] = "发动 连计，选择两名角色，令第一个选择的角色对第二个选择的角色发起“军令”<br />" ..
  --   "若后者执行，其对前者发起强制执行的“军令”；<br />不执行，你对前者和后者各造成1点伤害",
  -- ["#wk_heg__lianji1-active"] = "发动 连计，再选择一名角色，令 %src 对其发起“军令”<br />" ..
  --   "若其：执行，其对 %src 发起强制执行的“军令”；<br />不执行，你对 %src 和其各造成1点伤害",
  -- ["#wk_heg__lianji2-active"] = "发动 连计，令 %src 对 %dest 发起“军令”，<br />" ..
  --   "若 %dest ：执行，其对 %src 发起强制执行的“军令”；<br />不执行，你对 %src 和 %dest 各造成1点伤害",
  ["~wk_heg__wangyun"] = "获罪于君，当伏大辟以谢天下…",
}

local zhongyao = General(extension, "wk_heg__zhongyao", "wei", 3)

local chengqi = fk.CreateTriggerSkill{
  name = "wk_heg__chengqi",
  anim_type = "special",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and data.from == player.id and (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = TargetGroup:getRealTargets(data.tos)
    local chooses = table.map(room.alive_players, Util.IdMapper)
    local tos, id = room:askForChooseCardAndPlayers(player, chooses, 1, #targets, ".|.|spade|.|.|.", "#wk_heg__chengqi-choose", self.name, true)
    if #tos ~= 0 then
      self.cost_data = {tos, id}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.tos = {}
    local to = self.cost_data[1]
    local id = self.cost_data[2]
    room:throwCard({id}, self.name, player, player)
    for i = 1, #to, 1 do
      TargetGroup:pushTargets(data.tos, to[i])
    end
  end,
}

local xunzuo = fk.CreateTriggerSkill{
  name = "wk_heg__xunzuo",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and H.compareKingdomWith(player, target) and H.getGeneralsRevealedNum(target) == 2 and target.phase == Player.Finish and (player == target or H.hasShownSkill(player, self))
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local skills = {}
    local general = Fk.generals[target.general]
    local deputy = Fk.generals[target.deputyGeneral]
    for _, s in ipairs(general:getSkillNameList()) do
      if target:hasSkill(s) then
        table.insert(skills, s)
      end
    end
    for _, s in ipairs(deputy:getSkillNameList()) do
      if target:hasSkill(s) then
        table.insert(skills, s)
      end
    end
    local choice_lose = room:askForChoice(target, skills, self.name)
    room:handleAddLoseSkills(target, "-"..choice_lose, nil)

    local all_choices = {"wk_heg__hs__yiji", "wk_heg__quhu", "wk_heg__hs__weimu", "wk_heg__ld__qice", "wk_heg__wk_heg__choulue"}
    local choices = {}
    local skills = {}
    for _, p in ipairs(room.alive_players) do
      for _, s in ipairs(p.player_skills) do
        table.insert(skills, s.name)
      end
    end
    for _, skill in ipairs(all_choices) do
      local skillNames = {skill, skill:sub(9)}
      local can_choose = true
      for _, sname in ipairs(skills) do
        if table.contains(skillNames, sname) then
          can_choose = false
          break
        end
      end
      if can_choose then table.insert(choices, skill) end
    end
    if #choices == 0 then return false end
    local result = room:askForCustomDialog(target, self.name,
    "packages/utility/qml/ChooseSkillBox.qml", {
      choices, 1, 1, "#wk_heg__xunzuo-choice"
    })
    if result == "" then return false end
    local choice = json.decode(result)[1]
    room:handleAddLoseSkills(target, choice, nil)
    room:setPlayerMark(target, "wk_heg__xunzuo-turn", 1)
    room:setPlayerMark(target, "_heg__BattleRoyalMode_ignore", 1)
  end,
}

local choulueXZ = fk.CreateTriggerSkill{
  name = "wk_heg__wk_heg__choulue",
  anim_type = "offensive",
  events = {fk.Damaged, fk.TargetSpecified},
  can_trigger = function (self, event, target, player, data)
    if event == fk.Damaged then
      return player == target and player:hasSkill(self) and player:getMark("@!yinyangfish") < player.maxHp
    else
      return player:hasSkill(self) and H.compareKingdomWith(player, target) and #AimGroup:getAllTargets(data.tos) == 1
        and data.card:isCommonTrick() and player:getMark("@!yinyangfish") ~= 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, event == fk.Damaged and "#wk_heg__choulue-getfish" or "#wk_heg__choulue-twice")
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      H.addHegMark(room, player, "yinyangfish")
    else
      room:removePlayerMark(player, "@!yinyangfish")
      if player:getMark("@!yinyangfish") == 0 then
        player:loseFakeSkill("yinyangfish_skill&")
      end
      data.additionalEffect = 1
    end
  end,
}

local weimuXZ = fk.CreateTriggerSkill{
  name = "wk_heg__hs__weimu",
  anim_type = "defensive",
  events = { fk.TargetConfirming, fk.BeforeCardsMove },
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.TargetConfirming then
      return target == player and data.card.color == Card.Black and data.card:isCommonTrick()
    elseif event == fk.BeforeCardsMove then
      local id = 0
      local source = player
      local room = player.room
      local c
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerJudge then
          for _, info in ipairs(move.moveInfo) do
            id = info.cardId
            if info.fromArea == Card.PlayerJudge then
              source = room:getPlayerById(move.from) or player
            else
              source = player
            end
            c = source:getVirualEquip(id)
            --FIXME：巨大隐患，延时锦囊的virtual_equips在置入判定区的事件被篡改，或者判定阶段自然流程以外的方式离开判定区时不会清理
            if not c then c = Fk:getCardById(id) end
            if c.sub_type == Card.SubtypeDelayedTrick and c.color == Card.Black then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirming then
      AimGroup:cancelTarget(data, player.id)
      return true
    elseif event == fk.BeforeCardsMove then
      local source = player
      local mirror_moves = {}
      local ids = {}
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerJudge then
          local move_info = {}
          local mirror_info = {}
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if info.fromArea == Card.PlayerJudge then
              source = room:getPlayerById(move.from) or player
            else
              source = player
            end
            local c = source:getVirualEquip(id)
            if not c then c = Fk:getCardById(id) end
            if c.sub_type == Card.SubtypeDelayedTrick and c.color == Card.Black then
              table.insert(mirror_info, info)
              table.insert(ids, id)
            else
              table.insert(move_info, info)
            end
          end
          if #mirror_info > 0 then
            move.moveInfo = move_info
            local mirror_move = table.clone(move)
            mirror_move.to = nil
            mirror_move.toArea = Card.DiscardPile
            mirror_move.moveInfo = mirror_info
            table.insert(mirror_moves, mirror_move)
          end
        end
      end
      table.insertTable(data, mirror_moves)
    end
  end,
}

local qiceXZ = fk.CreateActiveSkill{
  name = "wk_heg__ld__qice",
  prompt = "#ld__qice-active",
  interaction = function()
    local handcards = Self:getCardIds(Player.Hand)
    local names, all_names = {} , {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and not table.contains(all_names, card.name) then
        table.insert(all_names, card.name)
        local to_use = Fk:cloneCard(card.name)
        to_use:addSubcards(handcards)
        if Self:canUse(to_use) and not Self:prohibitUse(to_use) then
          local x = 0
          if to_use.multiple_targets and to_use.skill:getMinTargetNum() == 0 then
            for _, p in ipairs(Fk:currentRoom().alive_players) do
              if not Self:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, Self.id, card, true) then
                x = x + 1
              end
            end
          end
          if x <= Self:getHandcardNum() then
            table.insert(names, card.name)
          end
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names, all_choices = all_names}
  end,
  card_num = 0,
  min_target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if self.interaction.data == nil then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use.skillName = self.name
    to_use:addSubcards(Self:getCardIds(Player.Hand))
    if not to_use.skill:targetFilter(to_select, selected, selected_cards, to_use) then return false end
    if (#selected == 0 or to_use.multiple_targets) and
    Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), to_use) then return false end
    if to_use.multiple_targets then
      if #selected >= Self:getHandcardNum() then return false end
      if to_use.skill:getMaxTargetNum(Self, to_use) == 1 then
        local x = 0
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          if p.id == to_select or (not Self:isProhibited(p, to_use) and to_use.skill:modTargetFilter(p.id, {to_select}, Self.id, to_use, true)) then
            x = x + 1
          end
        end
        if x > Self:getHandcardNum() then return false end
      end
    end
    return true
  end,
  feasible = function(self, selected, selected_cards)
    if self.interaction.data == nil then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use.skillName = self.name
    to_use:addSubcards(Self:getCardIds(Player.Hand))
    return to_use.skill:feasible(selected, selected_cards, Self, to_use)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local use = {
      from = player.id,
      tos = table.map(effect.tos, function (id)
        return {id}
      end),
      card = Fk:cloneCard(self.interaction.data),
    }
    use.card:addSubcards(player:getCardIds(Player.Hand))
    use.card.skillName = self.name
    room:useCard(use)
    if not player.dead and player:getMark("@@wk_heg__ld__qice_transform") == 0 and room:askForChoice(player, {"transform_deputy", "Cancel"}, self.name) ~= "Cancel" then
      room:setPlayerMark(player, "@@wk_heg__ld__qice_transform", 1)
      H.transformGeneral(room, player)
    end
  end,
}

local yijiXZ = fk.CreateTriggerSkill{
  name = "wk_heg__hs__yiji",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(2)
    while true do
      room:setPlayerMark(player, "hs__yiji_cards", ids)
      local _, ret = room:askForUseActiveSkill(player, "hs__yiji_active", "#hs__yiji-give", true, nil, true)
      room:setPlayerMark(player, "hs__yiji_cards", 0)
      if ret then
        for _, id in ipairs(ret.cards) do
          table.removeOne(ids, id)
        end
        room:moveCardTo(ret.cards, Card.PlayerHand, room:getPlayerById(ret.targets[1]), fk.ReasonGive, self.name, nil, false, player.id)
        if #ids == 0 then break end
        if player.dead then
          room:moveCards({
            ids = ids,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonJustMove,
            skillName = self.name,
          })
          break
        end
      else
        room:moveCardTo(ids, Player.Hand, player, fk.ReasonGive, self.name, nil, false, player.id)
        break
      end
    end
  end,
}

local quhuXZ = fk.CreateActiveSkill{
  name = "wk_heg__quhu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and Self:canPindian(target) and target.hp > Self.hp
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      local targets = {}
      for _, p in ipairs(room:getOtherPlayers(target)) do
        if target:inMyAttackRange(p) then
          table.insert(targets, p.id)
        end
      end
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#quhu-choose", self.name)
      room:damage{
        from = target,
        to = room:getPlayerById(tos[1]),
        damage = 1,
        skillName = self.name,
      }
    else
      room:damage{
        from = target,
        to = player,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}

zhongyao:addSkill(chengqi)
zhongyao:addSkill(xunzuo)
zhongyao:addRelatedSkill(choulueXZ)
zhongyao:addRelatedSkill(weimuXZ)
zhongyao:addRelatedSkill(qiceXZ)
zhongyao:addRelatedSkill(yijiXZ)
zhongyao:addRelatedSkill(quhuXZ)
Fk:loadTranslationTable{
  ["wk_heg__zhongyao"] = "钟繇",
  ["designer:wk_heg__zhongyao"] = "教父&静谦&祭祀",
  ["wk_heg__chengqi"] = "承启",
  [":wk_heg__chengqi"] = "当你使用基本牌或普通锦囊牌选择目标后，你可弃置一张黑桃牌，为此牌重新指定至多等量个目标（无视合法性）。",
  ["wk_heg__xunzuo"] = "勋佐",
  [":wk_heg__xunzuo"] = "与你势力相同角色的结束阶段，若其武将牌均明置，你可以令其选择并失去武将牌上一个技能，然后其选择并获得下列一个所有角色均没有的技能：遗计，驱虎，帷幕，奇策，筹略，且其无视“鏖战”规则直至游戏结束。",

  ["#wk_heg__chengqi-choose"] = "承启：你可以弃置一张黑桃牌，为此牌重新指定至多等量个目标",
  -- ["#wk_heg__xunzuo-choose"] = "勋佐：请选择一个技能失去",
  ["#wk_heg__xunzuo-choice"] = "勋佐：请选择一个技能获得",

  ["_heg__BattleRoyalMode_ignore"] = "无视鏖战",

  ["wk_heg__hs__yiji"] = "遗计",
  [":wk_heg__hs__yiji"] = "当你受到伤害后，你可观看牌堆顶两张牌，然后你可将这些牌交给任意角色。",
  ["wk_heg__quhu"] = "驱虎", 
  [":wk_heg__quhu"] = "出牌阶段限一次，你可以与一名体力值大于你的角色拼点，若你：赢，你令其对其攻击范围内的一名角色造成1点伤害；没赢，其对你造成1点伤害。", 
  ["wk_heg__hs__weimu"] = "帷幕",
  [":wk_heg__hs__weimu"] = "锁定技，当你成为黑色锦囊牌的目标时，取消之。",
  ["wk_heg__ld__qice"] = "奇策",
  [":wk_heg__ld__qice"] = "出牌阶段限一次，你可以将所有手牌当做一张指定目标数不大于X的任意普通锦囊牌使用（X为你的手牌数），然后你可变更一次副将。",
  ["@@wk_heg__ld__qice_transform"] = "奇策 已变更",
  ["wk_heg__wk_heg__choulue"] = "筹略",
  [":wk_heg__wk_heg__choulue"] = "①当你受到伤害后，若你的“阴阳鱼”标记数小于你体力上限，你可获得一个“阴阳鱼”标记；②与你势力相同的角色使用普通锦囊牌指定唯一目标后，你可移去一个“阴阳鱼”标记，令此牌结算两次。",

  ["$wk_heg__chengqi1"] = "世有十万字形，亦当有十万字体。",
  ["$wk_heg__chengqi2"] = "笔画如骨，不可据于一形。",
  ["$wk_heg__xunzuo1"] = "只有忠心，没有谋略，是不够的",
  ["$wk_heg__xunzuo2"] = "承君恩宠，报效国家。",

  ["~wk_heg__zhongyao"] = "",
}

local zhugezhan = General(extension, "wk_heg__zhugezhan", "shu", 4, 4, General.Male)
zhugezhan.deputyMaxHpAdjustedValue = -1
local zuilun = fk.CreateTriggerSkill{
  name = "wk_heg__zuilun",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Finish
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local all_choices = {"wk_heg__zuilun-chain", "wk_heg__zuilun-discard", "wk_heg__zuilun-losehp"}
    local choices = table.clone(all_choices)
    for i = 3, 1, -1 do
      local c = all_choices[i]
      if player:getMark(c) > 0 then
        table.remove(choices, i)
      end
    end
    if #choices == 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "wk_heg__zuilun-choose", self.name, false)
      local to = room:getPlayerById(tos[1])
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    else
      room:notifySkillInvoked(player, self.name, "negative")
      local choice = room:askForChoice(player, choices, self.name, nil, false, all_choices)
      if choice == "wk_heg__zuilun-chain" then
        player:setChainState(true)
      elseif choice == "wk_heg__zuilun-discard" then
        local n = player:getHandcardNum() - 1
        if n > 0 then
          room:askForDiscard(player, n, n, false, self.name, false)
        end
      elseif choice == "wk_heg__zuilun-losehp" then
        local n = player.hp - 1
        if n > 0 then
          room:loseHp(player, n, self.name)
        end
      end
      room:setPlayerMark(player, choice, 1)
    end
  end,
}

local longfei = fk.CreateTriggerSkill{
  name = "wk_heg__longfei",
  array_type = "formation",
  relate_to_place = "m",
}

local longfeiTrig = fk.CreateTriggerSkill{
  name = "#wk_heg__longfei_trigger",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(longfei) and #player.room.alive_players >= 4 and H.inFormationRelation(player, target) and target.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, longfei.name)
    player:broadcastSkillInvoke(longfei.name)
    local num = 0
    for _, p in ipairs(room.alive_players) do
      if H.inFormationRelation(p, player) then
        num = num + 1
      end
    end
    room:askForGuanxing(player, room:getNCards(num))
  end,
}

local kuangzhis = fk.CreateTriggerSkill{
  name = "wk_heg__kuangzhis",
  anim_type = "special",
  relate_to_place = "d",
  events = {fk.Damage, fk.AfterDying},
  can_trigger = function (self, event, target, player, data)
    if event == fk.Damage then
      if not (player:hasSkill(self) and H.compareKingdomWith(player, target) and player.room.current == target) then return false end
      local events = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data[1].from == target
      end, Player.HistoryTurn)
      return #events == 1 and events[1].data[1] == data
    else
      return player:hasSkill(self) and target and not target.dead and player == target
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.Damage then
      return player.room:askForSkillInvoke(player, self.name, nil, "wk_heg__kuangzhis-drawcard")
    else
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      if not target.dead then
        target:drawCards(1, self.name)
      end
      if not player.dead then
        player:drawCards(1, self.name)
      end
    else
      SwapMainAndDeputy(room, player)
      local targets = {}
      local n = -1
      for _, p in ipairs(room.alive_players) do
        if H.compareKingdomWith(p, player, true) then
          if p:getHandcardNum() > n then
            targets = {p.id}
            n = p:getHandcardNum()
          elseif p:getHandcardNum() == n then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "wk_heg__kuangzhis-choose", self.name, false)
      local to = room:getPlayerById(tos[1])
      room:useVirtualCard("duel", nil, player, to, self.name)
    end
  end,
}

zhugezhan:addSkill(zuilun)
longfei:addRelatedSkill(longfeiTrig)
zhugezhan:addSkill(longfei)
zhugezhan:addSkill(kuangzhis)

Fk:loadTranslationTable{
  ["wk_heg__zhugezhan"] = "诸葛瞻",
  ["designer:wk_heg__zhugezhan"] = "教父&二四&635",
  ["wk_heg__zuilun"] = "罪论",
  [":wk_heg__zuilun"] = "锁定技，结束阶段，你执行并移除一项：1.横置；2.弃置手牌至一张；3.失去体力至1点；若均已执行过，则改为对一名其他角色造成1点伤害。",
  ["wk_heg__longfei"] = "龙飞",
  [":wk_heg__longfei"] = "主将技，阵法技，与你处于同一队列角色的准备阶段，你观看牌堆顶X张牌并将这些牌以任意顺序置于牌堆顶或牌堆底（X为与你处于同一队列角色数）。",
  ["wk_heg__kuangzhis"] = "匡志",
  [":wk_heg__kuangzhis"] = "副将技，此武将牌上单独的阴阳鱼个数-1；①与你势力相同的角色于其回合内首次造成伤害后，你可与其各摸一张牌；②当你进入濒死状态被救回后，你交换主副将，然后视为对一名与你势力不同且手牌数为其中最多的角色使用一张【决斗】。<br />"..
  "<font color = 'gray'>注：若不能交换主副将，则二效果也仅会发动一次，后期修复。</font>",

  ["wk_heg__zuilun-chain"] = "横置",
  ["wk_heg__zuilun-discard"] = "弃置手牌至一张",
  ["wk_heg__zuilun-losehp"] = "失去体力至1点",
  ["wk_heg__zuilun-choose"] = "罪论：你对一名其他角色造成1点伤害",

  ["#wk_heg__longfei_trigger"] = "龙飞",

  ["wk_heg__kuangzhis-drawcard"] = "匡志：你可与当前回合角色各摸一张牌",
  ["wk_heg__kuangzhis-choose"] = "匡志：选择一名手牌数全场最多且与你势力不同的角色，视为对其使用一张【决斗】",


  ["$wk_heg__zuilun1"] = "",
  ["$wk_heg__zuilun2"] = "",
  ["$wk_heg__longfei1"] = "",
  ["$wk_heg__longfei2"] = "",
  ["$wk_heg__kuangzhi1"] = "",
  ["$wk_heg__kuangzhi2"] = "",

  ["~wk_heg__zhugezhan"] = "临难而死义，无愧先父…",
}

local sunshao = General(extension, "wk_heg__sunshao", "wu", 3, 3, General.Male)

local wk_heg__zhiheng = fk.CreateActiveSkill{
  name = "wk_heg__zhiheng",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  target_num = 0,
  min_card_num = 1,
  max_card_num = function()
    return table.find(Self:getEquipments(Card.SubtypeTreasure), function(cid)
      return Fk:getCardById(cid).name == "luminous_pearl"
    end) and 998 or Self.maxHp
  end,
  card_filter = function(self, to_select, selected)
    if #selected >= Self.maxHp then
      return table.find(Self:getEquipments(Card.SubtypeTreasure), function(cid)
        return Fk:getCardById(cid).name == "luminous_pearl" and not table.contains(selected, cid) and to_select ~= cid
      end)
    end
    return #selected < Self.maxHp and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, from, from)
    if not from.dead then
      from:drawCards(#effect.cards, self.name)
    end
  end
}

local function getTrueSkills(player)
  local skills = {}
  for _, s in ipairs(Fk.generals[player.general]:getSkillNameList()) do
    table.insertIfNeed(skills, s)
  end
  for _, s in ipairs(Fk.generals[player.deputyGeneral]:getSkillNameList()) do
    table.insertIfNeed(skills, s)
  end
  return skills
end

local bizheng = fk.CreateTriggerSkill{
  name = "wk_heg__bizheng",
  anim_type = "special",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local current = room.current
      local cards = {}
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.from and move.from == current.id and not room:getPlayerById(move.from).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insert(cards, info.cardId)
              cards = U.moveCardsHoldingAreaCheck(room, cards)
            end
          end
        end
      end
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCards{
      ids = self.cost_data,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    }
    local card = player:getCardIds("he")
    local skills = #getTrueSkills(room.current)
    if #card > skills then
      card = room:askForCard(player, skills, skills, true, self.name, false)
    end
    room:moveCards({
      ids = card,
      from = player.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      proposer = player.id,
    })
    room:askForGuanxing(player, room:getNCards(#card), nil, {0, 0}, self.name)
    room:handleAddLoseSkills(room.current, wk_heg__zhiheng.name, nil)
  end,
}

local ceci = fk.CreateTriggerSkill{
  name = "wk_heg__ceci",
  anim_type = "special",
  events = {fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() < player.maxHp then
      player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    end
    local targets = table.map(table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(p, player) and (p:hasSkill("wk_heg__zhiheng") or p:hasSkill("hs__zhiheng")
        or p:hasSkill("ld__lordsunquan_zhiheng") or p:hasSkill("luminous_pearl_skill")) end), Util.IdMapper)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__ceci-choose", self.name, false)
      local to = room:getPlayerById(tos[1])
      room:handleAddLoseSkills(to, "wk_heg__huanglong")
      local isMain = player.general == "wk_heg__sunshao" and true or false
      H.transformGeneral(room, player, isMain)
    end
  end,
}

local wk_heg__zhiheng_detach = fk.CreateTriggerSkill{
  name = "#wk_heg__zhiheng_detach",
  events = {fk.TurnStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("wk_heg__zhiheng", true, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-wk_heg__zhiheng", nil)
  end,
}

local huanglong = fk.CreateTriggerSkill{
  name = "wk_heg__huanglong",
  anim_type = "special",
  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  frequency = Skill.Compulsory,
  can_refresh = function(self, event, target, player, data)
    if event == fk.Deathed then
      return target:hasSkill("jiahe", true, true)
    else
      return data == self or data.name == "jiahe"
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local has_jiahe = false
    local targets = table.map(table.filter(player.room.alive_players, function(p)
      return p:hasSkill("jiahe") end), Util.IdMapper)
    if #targets > 0 then has_jiahe = true end
    if player:hasSkill(self) then
      room:handleAddLoseSkills(player, has_jiahe and "-wk_heg__jiahe" or "wk_heg__jiahe", nil, false, true)
      room:handleAddLoseSkills(player, has_jiahe and "-#wk_heg__fenghuotu" or "#wk_heg__fenghuotu", nil, false, true)
      room:handleAddLoseSkills(player, has_jiahe and "-wk_heg__jubao" or "wk_heg__jubao", nil, false, true)
      room:setPlayerMark(player, "@@wk_heg__huanglong_skill", has_jiahe and 0 or 1)
      room:setPlayerMark(player, "@@wk_heg__huanglong_change", has_jiahe and 1 or 0)
      room.logic:trigger("fk.HuangLongDetect", nil, self.name)
    end
  end,
}

local wk_heg__jubao = fk.CreateTriggerSkill{
  name = "wk_heg__jubao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self) and player.phase == Player.Finish) then return false end
    for _, id in ipairs(player.room.discard_pile) do
      if Fk:getCardById(id).name == "luminous_pearl" then
        return true
      end
    end
    return table.find(Fk:currentRoom().alive_players, function(p)
      return table.find(p:getEquipments(Card.SubtypeTreasure), function(cid)
        return Fk:getCardById(cid).name == "luminous_pearl"
      end)
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local targets = table.map(table.filter(room.alive_players, function(p)
      return table.find(p:getEquipments(Card.SubtypeTreasure), function(cid)
        return Fk:getCardById(cid).name == "luminous_pearl"
      end) end), Util.IdMapper)
    if #targets > 0 then
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if p == player then
          local card = room:askForCardChosen(player, p, "e", self.name)
          room:obtainCard(player.id, card, false, fk.ReasonPrey)
        else
          local card = room:askForCardChosen(player, p, "he", self.name)
          room:obtainCard(player.id, card, false, fk.ReasonPrey)
        end
      end
    end
  end,
}

local wk_heg__jubao_move = fk.CreateTriggerSkill{
  name = "#wk_heg__jubao_move",
  events = {fk.BeforeCardsMove},
  frequency = Skill.Compulsory,
  anim_type = "defensive",
  -- main_skill = "jubao",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or not (player:getEquipment(Card.SubtypeTreasure)) then return false end
    for _, move in ipairs(data) do
      if move.from == player.id and move.to ~= move.from and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and table.contains({Card.SubtypeTreasure}, Fk:getCardById(info.cardId).sub_type) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local ids = {}
    player.room:notifySkillInvoked(player, "wk_heg__jubao", "defensive")
    player:broadcastSkillInvoke("wk_heg__jubao")
    for _, move in ipairs(data) do
      if move.from == player.id and move.to ~= move.from and move.toArea == Card.PlayerHand then
        local move_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if info.fromArea == Card.PlayerEquip and table.contains({Card.SubtypeTreasure}, Fk:getCardById(id).sub_type) then
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #ids > 0 then
          move.moveInfo = move_info
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#cancelDismantle",
        card = ids,
        arg = self.name,
      }
    end
  end,
}

local wk_heg__jiahe = fk.CreateTriggerSkill{
  name = "wk_heg__jiahe",
  anim_type = "support",
  frequency = Skill.Compulsory,
  derived_piles = "lord_fenghuo",
  can_trigger = Util.FalseFunc,
}

local wk_heg__fenghuotu = fk.CreateTriggerSkill{
  name = "#wk_heg__fenghuotu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function (self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return H.compareKingdomWith(player, target) and player:hasSkill(self) and #player:getPile("lord_fenghuo") > 0 and target.phase == Player.Start
    else
      return player == target and player:hasSkill(self) and data.card and #player:getPile("lord_fenghuo") > 0 and (data.card.type == Card.TypeTrick or data.card.trueName == "slash")
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return true
    else
      local card = player.room:askForCard(player, 1, 1, false, self.name, false, ".|.|.|lord_fenghuo", "#ld__jiahe_damaged", "lord_fenghuo")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local skills = {"ld__lordsunquan_yingzi", "ld__lordsunquan_haoshi", "ld__lordsunquan_shelie", "ld__lordsunquan_duoshi"}
      local num = #player:getPile("lord_fenghuo") >= 5 and 2 or 1
      local result = room:askForCustomDialog(target, self.name,
      "packages/utility/qml/ChooseSkillBox.qml", {
        table.slice(skills, 1, #player:getPile("lord_fenghuo") + 1), 0, num, "#fenghuotu-choose:::" .. tostring(num)
      })
      if result == "" then return false end
      local choice = json.decode(result)
      if #choice > 0 then
        room:handleAddLoseSkills(target, table.concat(choice, "|"), nil, true, false)
        room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
          room:handleAddLoseSkills(target, '-' .. table.concat(choice, "|-"), nil, true, false)
        end)
      end
    else
      room:moveCardTo(self.cost_data, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, "lord_fenghuo", true, player.id)
    end
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed, fk.GeneralRevealed, "fk.HuangLongDetect"},
  can_refresh = function(self, event, target, player, data)
    if event ~= "fk.HuangLongDetect" and player ~= target then return false end
    if event == fk.Deathed then return player:hasSkill(self.name, true, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then return data == self
    else return true end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local players = room.alive_players
    local lordsunquans = table.filter(players, function(p) return H.hasShownSkill(p, self) end)
    local jiahe_map = {}
    for _, p in ipairs(players) do
      local will_attach = false
      for _, ld in ipairs(lordsunquans) do
        if H.compareKingdomWith(ld, p) then
          will_attach = true
          break
        end
      end
      jiahe_map[p] = will_attach
    end
    for p, v in pairs(jiahe_map) do
      if v ~= p:hasSkill("wk_heg__jiahe_other&") then
        room:handleAddLoseSkills(p, v and "wk_heg__jiahe_other&" or "-wk_heg__jiahe_other&", nil, false, true)
      end
    end
  end,
}

local wk_heg__jiaheOther = fk.CreateActiveSkill{
  name = "wk_heg__jiahe_other&",
  prompt = function()
    local targets = table.map(table.filter(Fk:currentRoom().alive_players, function(p)
      return p:getMark("@@wk_heg__huanglong_skill") ~= 0 end), Util.IdMapper)
    return "#ld__jiahe_other:" .. targets[1]
  end,
  can_use = function(self, player)
    local room = Fk:currentRoom()
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:getMark("@@wk_heg__huanglong_skill") ~= 0 end), Util.IdMapper)
    local target = room:getPlayerById(targets[1])
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and target and target:hasSkill("wk_heg__jiahe")
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:getMark("@@wk_heg__huanglong_skill") ~= 0 end), Util.IdMapper)
    local target = room:getPlayerById(targets[1])
    if target and target:hasSkill("wk_heg__jiahe") then
      target:addToPile("lord_fenghuo", effect.cards, true, self.name)
    end
  end,
}

sunshao:addSkill(bizheng)
sunshao:addSkill(ceci)

wk_heg__jubao:addRelatedSkill(wk_heg__jubao_move)
wk_heg__zhiheng:addRelatedSkill(wk_heg__zhiheng_detach)
sunshao:addRelatedSkill(wk_heg__zhiheng)
sunshao:addRelatedSkill(huanglong)

sunshao:addRelatedSkill(wk_heg__jiahe)
sunshao:addRelatedSkill(wk_heg__jubao)
Fk:addSkill(wk_heg__fenghuotu)
Fk:addSkill(wk_heg__jiaheOther)

Fk:loadTranslationTable{
  ["wk_heg__sunshao"] = "孙邵",
  ["designer:wk_heg__sunshao"] = "教父&祭祀&二四&边缘&风箫",
  ["wk_heg__bizheng"] = "弼政",
  [":wk_heg__bizheng"] = "每回合限一次，当前回合角色的牌因弃置而置入弃牌堆后，你可获得之并将X张牌置于牌堆顶，然后其获得〖制衡〗直至其回合开始。（X为其已明置武将牌上技能数）",
  ["wk_heg__ceci"] = "册辞",
  [":wk_heg__ceci"] = "每轮结束时，你可将手牌摸至体力上限，然后若存在与你势力相同且拥有〖制衡〗的角色，其获得〖黄龙〗，你变更此武将牌。",

  ["wk_heg__huanglong"] = "黄龙",
  [":wk_heg__huanglong"] = "锁定技，若存在拥有〖嘉禾〗的角色，你令其失去〖烽火〗的条件删去“受到锦囊牌造成的伤害后”，否则你视为拥有〖嘉禾〗和〖聚宝〗。",

  ["#wk_heg__ceci-choose"] = "册辞：选择一名与你势力相同且拥有〖制衡〗的角色，其获得〖黄龙〗",

  ["wk_heg__zhiheng"] = "制衡",
  [":wk_heg__zhiheng"] = "出牌阶段限一次，你可弃置至多X张牌（X为你的体力上限），摸等量的牌。<font color='grey'><small>此为〖制衡（弼政）〗</small></font>",
  ["@@wk_heg__huanglong_skill"] = "黄龙 拥有技能",
  ["@@wk_heg__huanglong_change"] = "黄龙 加强技能",

  ["wk_heg__jiahe"] = "嘉禾",
  [":wk_heg__jiahe"] = "<b><font color='goldenrod'>君主技</font></b>，你拥有“缘江烽火图”。<br>" ..
  "#<b>缘江烽火图</b>：①吴势力角色出牌阶段限一次，其可将一张装备牌置于“缘江烽火图”上，称为“烽火”。<br>" ..
  "②吴势力角色的准备阶段，其可根据“烽火”数量选择获得对应的技能直至其回合结束：<br>"..
  "不小于一，〖英姿〗；不小于二，〖好施〗；不小于三，〖涉猎〗；不小于四，〖度势〗；不小于五，可额外选择一项。<br>"..
  "③锁定技，当你受到【杀】或锦囊牌造成的伤害后，你将一张“烽火”置入弃牌堆。",
  ["wk_heg__jiahe_other&"] = "烽火图",
  [":wk_heg__jiahe_other&"] = "①出牌阶段限一次，你可以将一张装备牌置于“缘江烽火图”上，称为“烽火”。<br>" ..
  "②准备阶段，你可以根据“烽火”数量选择获得对应的技能直至其回合结束：<br>"..
  "不小于一，〖英姿〗；不小于二，〖好施〗；不小于三，〖涉猎〗；不小于四，〖度势〗；不小于五，可额外选择一项。",

  ["#wk_heg__jubao_move"] = "聚宝",
  ["wk_heg__jubao"] = "聚宝",
  [":wk_heg__jubao"] = "锁定技，①结束阶段，若弃牌堆或场上存在【定澜夜明珠】，你摸一张牌，然后获得拥有【定澜夜明珠】的角色的一张牌；②其他角色获得你装备区内的宝物牌时，取消之。",

  ["#wk_heg__fenghuotu"] = "烽火图",

  ["$wk_heg__bizheng1"] = "弼亮四世，正色率下。",
  ["$wk_heg__bizheng2"] = "弼佐辅君，国事正法。",
  ["$wk_heg__ceci1"] = "无传书卷记，功过自有评",
  ["$wk_heg__ceci2"] = "佚以典传，千秋谁记？",

  ["~wk_heg__sunshao"] = "此去一别，难见文举…",
}

--- 借调
---@param room Room
---@param player ServerPlayer
---@param target ServerPlayer
---@param deputyName string
---@param kingdom string
---@param isDeputy boolean
local function DoGiveDeputy(room, player, target, deputyName, kingdom, isDeputy)
  local orig = isDeputy and (player.deputyGeneral or "") or player.general
  orig = Fk.generals[orig]
  local orig_skills = orig and orig:getSkillNameList() or {}
  H.removeGeneral(room, player, isDeputy)
  room:handleAddLoseSkills(target, table.concat(orig_skills, "|"), nil, false)
  room:setPlayerMark(target, "@wk_give_deputy", deputyName)
  room:setPlayerMark(target, "@wk_give_deputy_kingdom", kingdom)
end

--- 结束借调
---@param room Room
---@param player ServerPlayer
---@param skillName string
local function StopGiveDeputy(room, player, skillName)
  local orig_string = player:getMark("@wk_give_deputy")
  local orig = Fk.generals[orig_string]
  local orig_skills = orig and orig:getSkillNameList() or {}
  orig_skills = table.map(orig_skills, function(e)
    return "-" .. e
  end)
  room:handleAddLoseSkills(player, table.concat(orig_skills, "|"), nil, false)

  local targets = table.map(table.filter(room.alive_players, function(p)
    return p.kingdom == player:getMark("@wk_give_deputy_kingdom") 
    and (p.deputyGeneral:startsWith("blank_") or p.general:startsWith("blank_")) end), Util.IdMapper)
  if #targets > 0 then
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#wk_give_deputy-choose", skillName, false)
    if #to > 0 then
      local target = room:getPlayerById(to[1])
      local choices = {}
      if target.deputyGeneral:startsWith("blank_") then
        table.insert(choices, "wk_give_deputy_back")
      end
      if target.general:startsWith("blank_") then
        table.insert(choices, "wk_give_main_back")
      end
      if #choices > 0 then
        local choice = room:askForChoice(player, choices, skillName)
        if choice == "wk_give_deputy_back" then
          room:changeHero(target, orig_string, false, true, true, false, false)
          room.logic:trigger("fk.GeneralTransformed", target, orig_string)
        else
          room:changeHero(target, orig_string, false, false, true, false, false)
          room.logic:trigger("fk.GeneralTransformed", target, orig_string)
        end
      end
    end
  end

  room:setPlayerMark(player, "@wk_give_deputy", 0)
  room:setPlayerMark(player, "@wk_give_deputy_kingdom", 0)
end

Fk:loadTranslationTable{
  ["@wk_give_deputy"] = "借调",
  ["@wk_give_deputy_kingdom"] = "属国",
}

local luzhi = General(extension, "wk_heg__luzhi", "qun", 3)

local zhenliang = fk.CreateTriggerSkill{
  name = "wk_heg__zhenliang",
  anim_type = "special",
  events = {fk.TurnedOver, fk.ChainStateChanged, fk.GeneralRevealed, fk.GeneralHidden, "fk.RemoveStateChanged", "fk.GeneralRemoved", "fk.GeneralTransformed"},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#wk_heg__zhenliang-ask::" .. target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"wk_heg__zhenliang-drawcard:"..target.id}
    if not target:isKongcheng() then
      table.insert(choices, "wk_heg__zhenliang-discard:"..target.id)
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice:startsWith("wk_heg__zhenliang-drawcard") then
      target:drawCards(1, self.name)
    else
      room:askForDiscard(target, 1, 1, true, self.name, false)
    end
    local choices = {"Cancel"}
    if player.general == "wk_heg__luzhi" or player.deputyGeneral == "wk_heg__luzhi" then
      table.insert(choices, 1, "wk_heg__zhenliang-give")
    end
    if room:askForChoice(target, choices, self.name) ~= "Cancel" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      if target.dead then return end
      local isDeputy = H.inGeneralSkills(player, self.name)
      if isDeputy then
        DoGiveDeputy(room, player, target, "wk_heg__luzhi", player.kingdom, isDeputy == "d")
      end
      room:setPlayerMark(player, "wk_give_deputy_luzhi", 1)
    end
  end,
}

local zhenliang_delay = fk.CreateTriggerSkill{
  name = "#wk_heg__zhenliang_delay",
  anim_type = "special",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target:getMark("wk_give_deputy_luzhi") == 1 and player:getMark("@wk_give_deputy") == "wk_heg__luzhi"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    StopGiveDeputy(player.room, player, self.name)
  end,
}

local function doImperialOrder(room, target)
  if target.dead then return end
  local all_choices = {"IO_reveal", "IO_discard", "IO_hplose"}
  local choices = table.clone(all_choices)
  if target.hp < 1 then table.remove(choices) end
  if table.every(target:getCardIds{Player.Equip, Player.Hand}, function(id) return Fk:getCardById(id).type ~= Card.TypeEquip or target:prohibitDiscard(Fk:getCardById(id)) end) then
    table.remove(choices, 2)
  end
  if (target.general ~= "anjiang" or target:prohibitReveal()) and (target.deputyGeneral ~= "anjiang" or target:prohibitReveal(true)) then
    table.remove(choices, 1)
  end
  if #choices == 0 then return false end
  local choice = room:askForChoice(target, choices, "imperial_order_skill", nil, false, all_choices)
  if choice == "IO_reveal" then
    H.askForRevealGenerals(room, target, "imperial_order_skill", true, true, false, false)
    target:drawCards(1, "imperial_order_skill")
  elseif choice == "IO_discard" then
    room:askForDiscard(target, 1, 1, true, "imperial_order_skill", false, ".|.|.|.|.|equip")
  else
    room:loseHp(target, 1, "imperial_order_skill")
  end
end

local lingli = fk.CreateActiveSkill{
  name = "wk_heg__lingli",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).color == Card.Black and not Self:prohibitDiscard(to_select)
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:getHandcardNum() > player:getHandcardNum() end), Util.IdMapper)
    room:sortPlayersByAction(targets)
    room:doIndicate(player.id, targets)
    for _, id in ipairs(targets) do
      local target = room:getPlayerById(id)
      doImperialOrder(room, target)
    end
  end,
}

zhenliang:addRelatedSkill(zhenliang_delay)
luzhi:addSkill(zhenliang)
luzhi:addSkill(lingli)

Fk:loadTranslationTable{
  ["wk_heg__luzhi"] = "卢植",
  ["wk_heg__lingli"] = "令礼",
  [":wk_heg__lingli"] = "出牌阶段限一次，你可弃置一张黑色牌，然后令所有手牌数大于你的角色执行【敕令】的效果。",
  ["wk_heg__zhenliang"] = "贞良",
  [":wk_heg__zhenliang"] = "其他角色的武将牌状态改变后，你可令其摸一张牌或弃置一张牌，然后其可受到你造成的1点伤害，令你借调此武将牌于其至你回合开始。"..
  "<font color = 'gray'>注：武将牌状态改变包括：明置、暗置、横置、叠置、移除、变更和调离。</font><br />"..
  "<font color = 'orange'>借调：借调角色执行借调流程时，移除对应的武将牌并将之置于目标角色的借调区内，视为该角色拥有此武将牌，借调区内的武将牌不为主副将且不能被移除、暗置和变更。"..
  "借调结束后，目标角色选择借调武将牌原本所属国家所有角色的一张士兵牌，令此士兵牌变更为借调武将牌。</font>",

  ["#wk_heg__zhenliang-ask"] = "你可对 %dest 发动〖贞良〗",
  ["wk_heg__zhenliang-discard"] = "令 %src 弃牌",
  ["wk_heg__zhenliang-drawcard"] = "令 %src 摸牌",

  ["wk_heg__zhenliang-give"] = "借调 卢植"
}


local zhangsong = General(extension, "wk_heg__zhangsong", "shu", 3)
local qiangzhi = fk.CreateTriggerSkill{
  name = "wk_heg__qiangzhi",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and target.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng() end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__qiangzhi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name, 1)
    room:notifySkillInvoked(player, self.name, "control")
    local to = room:getPlayerById(self.cost_data)
    room:doIndicate(player.id, {self.cost_data})
    local cards1 = room:askForCardsChosen(player, to, 1, 99, "h", self.name)
    to:showCards(cards1)

    local cards2 = player:getCardIds(Player.Hand)
    player:showCards(cards2)
    room:delay(300)

    local suit = {}
    for _, cid in ipairs(cards2) do
      local card = Fk:getCardById(cid)
      if not table.contains(suit, card.suit) then
        table.insert(suit, card.suit)
      end
    end
    local all_contain = true
    local card_name = {}
    for _, cid in ipairs(cards1) do
      local card = Fk:getCardById(cid)
      if not table.contains(suit, card.suit) then
        all_contain = false
        break
      end
      if not table.contains(card_name, card.name) then
        table.insert(card_name, card.name)
      end
    end
    if all_contain == true then
      room:setPlayerMark(target, "wk_heg__liance-phase", card_name)
      local success, dat = player.room:askForUseActiveSkill(target, "#wk_heg__liance_viewas", "#wk_heg__liance-choose", true)
      local card = Fk.skills["#wk_heg__liance_viewas"]:viewAs(card_name.cards)
        room:useCard{
        from = target.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
      }
    end
  end,
}

local xiantu = fk.CreateTriggerSkill{
  name = "wk_heg__xiantu",
  mute = true,
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Play and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCard(player, 2, 2, true, self.name, true, ".", "#wk_heg__xiantu-give::"..target.id)
    if #cards == 2 then 
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name, 1)
    room:doIndicate(player.id, {target.id})
    room:moveCardTo(self.cost_data, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    room:setPlayerMark(player, "xiantu-phase", 1)
  end,
}

local xiantu_trigger = fk.CreateTriggerSkill{
  name = "#wk_heg__xiantu_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target.phase == Player.Play and player:getMark("xiantu-phase") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player.room.logic:getEventsOfScope(GameEvent.Death, 1, function(e)
          local death = e.data[1]
          return death.damage and death.damage.from == target
        end, Player.HistoryPhase) == 0 then
      player:broadcastSkillInvoke("wk_heg__xiantu", 2)
      room:notifySkillInvoked(player, "wk_heg__xiantu", "negative")
      room:loseHp(player, 1, self.name)
    else
      player:broadcastSkillInvoke("wk_heg__xiantu", 1)
      room:notifySkillInvoked(player, "wk_heg__xiantu", "positive")
      player:drawCards(2, self.name)
      room:handleAddLoseSkills(player, "-wk_heg__xiantu", nil)
    end
  end,
}

xiantu:addRelatedSkill(xiantu_trigger)
zhangsong:addSkill(qiangzhi)
zhangsong:addSkill(xiantu)
Fk:loadTranslationTable{
  ["wk_heg__zhangsong"] = "张松",
  ["#wk_heg__zhangsong"] = "怀璧待凤仪",
  ["designer:wk_heg__zhangsong"] = "教父&祭祀&朱古力&边缘",
  ["wk_heg__qiangzhi"] = "强识",
  [":wk_heg__qiangzhi"] = "结束阶段，你可展示一名其他角色任意张手牌，然后你展示所有手牌，若包含其展示的所有花色，你可视为使用其展示的一张基本牌或普通锦囊牌。",
  ["wk_heg__xiantu"] = "献图",
  [":wk_heg__xiantu"] = "其他角色的出牌阶段开始时，你可以交给其两张牌，若如此做，此阶段结束时，若其于此回合内杀死过角色，你摸两张牌并失去此技能，否则你失去1点体力。",

  ["#wk_heg__xiantu-give"] = "献图：选择交给 %dest 的两张牌",

  ["$wk_heg__qiangzhi1"] = "容我过目，即刻咏来。",
  ["$wk_heg__qiangzhi2"] = "文书强识，才可博于运筹。",
  ["$wk_heg__xiantu1"] = "将军莫虑，且看此图。",
  ["$wk_heg__xiantu2"] = "我已诚心相献，君何踌躇不前？",
  ["~wk_heg__zhangsong"] = "皇叔不听吾谏言，悔时晚矣！",
}

local wangji = General(extension, "wk_heg__wangji", "wei", 3, 3, General.Male)
local qizhi = fk.CreateTriggerSkill{
  name = "wk_heg__qizhi",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self) and target == player.room.current and H.compareKingdomWith(player, target)) then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local x = target:getMark("wk_heg__qizhi-turn")
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event and first_damage_event.data[1].from == target then
            x = first_damage_event.id
            room:setPlayerMark(target, "wk_heg__qizhi-turn", x)
            return true
          end
        end
      end, Player.HistoryTurn)
    end
    return damage_event.id == x
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return p ~= data.to and not p:isNude() end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__qizhi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if self.cost_data then
      local to = room:getPlayerById(self.cost_data)
      local id = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard(id, self.name, to, player)
      if not to.dead then
        to:drawCards(1, self.name)
      end
    end
  end,
}

local jinqu = fk.CreateTriggerSkill{
  name = "wk_heg__jinqu",
  anim_type = "drwacard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0  then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__jinqu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data then
      local to = room:getPlayerById(self.cost_data)
      to:drawCards(2, self.name)
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = turn_event.id
      local cards = {}
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              local card_suit = Fk:getCardById(info.cardId, true).suit
              if room:getCardArea(info.cardId) == Card.DiscardPile and not table.contains(cards, card_suit) and card_suit ~= 0 then
                table.insertIfNeed(cards, card_suit)
              end
            end
          end
        end
        return false
      end, end_id)
      local discard_num = to:getHandcardNum() - #cards
      if discard_num > 0 then
        room:askForDiscard(to, discard_num, discard_num, false, self.name, false)
      end
    end
  end,
}

wangji:addSkill(qizhi)
wangji:addSkill(jinqu)
Fk:loadTranslationTable{
  ["wk_heg__wangji"] = "王基", --魏国
  ["designer:wk_heg__wangji"] = "教父",
  ["wk_heg__qizhi"] = "奇制",
  [":wk_heg__qizhi"] = "与你势力相同的角色于其回合内首次造成伤害后，你可以弃置不为受伤角色的一张牌，然后以此法失去牌的角色摸一张牌。",
  ["wk_heg__jinqu"] = "进趋",
  [":wk_heg__jinqu"] = "每回合限一次，当你不因使用或打出而失去牌后，你可令一名与你势力相同的角色摸两张牌，然后其将手牌弃至X张（X为此回合进入弃牌堆的牌花色数）。",

  ["#wk_heg__qizhi-choose"] = "奇制：选择一名除受伤角色外的角色，弃置其一张牌",
  ["#wk_heg__jinqu-choose"] = "进趋：选择一名与你势力相同的角色，令其摸两张牌",

  ["$wk_heg__qizhi1"] = "声东击西，敌寇一网成擒。",
  ["$wk_heg__qizhi2"] = "吾意不在此地，已遣别部出发。",
  ["$wk_heg__jinqu1"] = "建上昶水城，以逼夏口！",
  ["$wk_heg__jinqu2"] = "通川聚粮，伐吴之业，当步步为营。",
  ["~wk_heg__wangji"] = "天下之势，必归大魏，可恨，未能得见呐！",
}


-- 封锁 判定区
local heg_judge_forbidden = fk.CreateTriggerSkill{
  name = "#heg_judge_forbidden",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("@@heg_judge_forbidden") ~= 0 and player == target and player.phase == Player.Judge
  end,
  on_use = Util.TrueFunc,
}

-- 封锁 手牌区
local heg_hand_forbidden = fk.CreateTriggerSkill{
  name = "#heg_hand_forbidden",
  anim_type = "control",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    return player:getMark("@@heg_hand_forbidden") ~= 0 and player == target
  end,
  on_use = function (self, event, target, player, data)
    data.toCard = nil
    data.tos = {}
  end,
}

-- 封锁 装备区
local heg_equip_forbidden = fk.CreateInvaliditySkill {
  name = "#heg_equip_forbidden",
  global = true,
  invalidity_func = function(self, from, skill)
    if from:getMark("@@heg_equip_forbidden") > 0 and skill.attached_equip then
      for _, card in ipairs(Fk.cards) do
        if card.type == Card.TypeEquip and skill.attached_equip == card.name then
          return true
        end
      end
    end
  end
}

Fk:loadTranslationTable{
  ["heg_judge_forbidden"] = "封锁 判定区",
  ["heg_hand_forbidden"] = "封锁 手牌区",
  ["heg_equip_forbidden"] = "封锁 装备区",

  ["@@heg_judge_forbidden"] = "封锁 判定区",
  ["@@heg_hand_forbidden"] = "封锁 手牌区",
  ["@@heg_equip_forbidden"] = "封锁 装备区",

  ["heg_judge_recover"] = "恢复 判定区",
  ["heg_hand_recover"] = "恢复 手牌区",
  ["heg_equip_recover"] = "恢复 装备区",

  ["#heg_equip_forbidden"] = "封锁",
  ["#heg_hand_forbidden"] = "封锁",
  ["#heg_judge_forbidden"] = "封锁",
}

local lihui = General(extension, "wk_heg__lihui", "shu", 3)
local ziqi = fk.CreateTriggerSkill{
  name = "wk_heg__ziqi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self) and H.compareKingdomWith(player, target) and target.phase == Player.Start
      and (player:getMark("@@heg_judge_forbidden") == 0 or player:getMark("@@heg_equip_forbidden") == 0 or player:getMark("@@heg_hand_forbidden") == 0)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    if player:getMark("@@heg_judge_forbidden") == 0 then
      table.insert(choices, "heg_judge_forbidden")
    end
    if player:getMark("@@heg_hand_forbidden") == 0 then
      table.insert(choices, "heg_hand_forbidden")
    end
    if player:getMark("@@heg_equip_forbidden") == 0 then
      table.insert(choices, "heg_equip_forbidden")
    end
    local choice = room:askForChoice(player, choices, self.name)
    room:setPlayerMark(player, "wk_heg__ziqi_forbidden", 1)
    if choice == "heg_judge_forbidden" then
      room:setPlayerMark(player, "wk_heg__ziqi_judge-turn", 1)
      room:setPlayerMark(player, "@@heg_judge_forbidden", 1)
    elseif choice == "heg_hand_forbidden" then
      room:setPlayerMark(player, "wk_heg__ziqi_hand-turn", 1)
      room:setPlayerMark(player, "@@heg_hand_forbidden", 1)
    else
      room:setPlayerMark(player, "wk_heg__ziqi_equip-turn", 1)
      room:setPlayerMark(player, "@@heg_equip_forbidden", 1)
    end
  end,

  refresh_events = {fk.TurnStart, fk.BuryVictim},
  can_refresh = function (self, event, target, player, data)
    return player:getMark("wk_heg__ziqi_forbidden") > 0 and target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "wk_heg__ziqi_forbidden", 0)
    room:setPlayerMark(player, "@@heg_judge_forbidden", 0)
    room:setPlayerMark(player, "@@heg_hand_forbidden", 0)
    room:setPlayerMark(player, "@@heg_equip_forbidden", 0)
    room.logic:trigger("fk.RecoverRegion", player, nil)
  end
}

local ziqi_trigger = fk.CreateTriggerSkill{
  name = "#wk_heg__ziqi_trigger",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function (self, event, target, player, data)
    return target and target == player.room.current and not H.compareKingdomWith(data.to, target) and player:usedSkillTimes(ziqi.name, Player.HistoryTurn) == 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    if player:getMark("wk_heg__ziqi_judge-turn") == 1 then
      player.room:setPlayerMark(data.to, "@@heg_judge_forbidden", 1)
    end
    if player:getMark("wk_heg__ziqi_hand-turn") == 1 then
      player.room:setPlayerMark(data.to, "@@heg_hand_forbidden", 1)
    end
    if player:getMark("wk_heg__ziqi_equip-turn") == 1 then
      player.room:setPlayerMark(data.to, "@@heg_equip_forbidden", 1)
    end
  end
}

ziqi:addRelatedSkill(ziqi_trigger)
ziqi:addRelatedSkill(heg_hand_forbidden)
ziqi:addRelatedSkill(heg_judge_forbidden)
ziqi:addRelatedSkill(heg_equip_forbidden)

local xingzhang = fk.CreateTriggerSkill{
  name = "wk_heg__xingzhang",
  anim_type = "control",
  events = {"fk.AfterCommandUse", "fk.RecoverRegion", fk.AfterDying},
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(self) and player:inMyAttackRange(target)) then return false end
    if event == "fk.AfterCommandUse" then
      return not target:isKongcheng()
    elseif event == "fk.RecoverRegion" then
      return true
    else
      return not target.dead
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == "fk.AfterCommandUse" then
      local card = room:askForCard(target, 1, 1, false, self.name, false)
      room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, self.name, nil, false, player.id)
      if not target.dead then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    elseif event == fk.AfterDying then
      local choices = {}
      if target:getMark("@@heg_judge_forbidden") ~= 0 then
        table.insert(choices, "heg_judge_recover")
      end
      if target:getMark("@@heg_hand_forbidden") ~= 0 then
        table.insert(choices, "heg_hand_recover")
      end
      if target:getMark("@@heg_equip_forbidden") ~= 0 then
        table.insert(choices, "heg_equip_recover")
      end
      if #choices == 0 then return false end
      local choice = room:askForChoice(target, choices, self.name)
      if choice == "heg_judge_forbidden" then
        room:setPlayerMark(target, "@@heg_judge_forbidden", 0)
      elseif choice == "heg_hand_forbidden" then
        room:setPlayerMark(target, "@@heg_hand_forbidden", 0)
      else
        room:setPlayerMark(target, "@@heg_equip_forbidden", 0)
      end
      room.logic:trigger("fk.RecoverRegion", target, nil)
    else
      H.askCommandTo(player, target, self.name, true)
    end
  end,
}

lihui:addSkill(ziqi)
lihui:addSkill(xingzhang)
Fk:loadTranslationTable{
  ["wk_heg__lihui"] = "李恢", --蜀国
  ["wk_heg__ziqi"] = "自器",
  [":wk_heg__ziqi"] = "回合开始时，你恢复所有区域；与你势力相同角色的准备阶段，你可以封锁一个区域，若如此做，直至此回合结束，其对与你势力不同的角色造成伤害后，受伤角色封锁对应的区域。"..
  "<font color = 'gray'>封锁：部分技能拥有封锁区域的效果，被封锁的区域内所有牌的技能无效，但原始牌面信息有效。",
  ["wk_heg__xingzhang"] = "刑张",
  [":wk_heg__xingzhang"] = "锁定技，你攻击范围内的角色：1.恢复区域后，你对其发起强制执行的“军令”；2.成为“军令”的目标结算后，其交给你一张手牌并回复1点体力；3.进入濒死状态被救回后，其恢复一个区域。",

  ["#wk_heg__ziqi_trigger"] = "自器",
}

local weiwenzhugezhi = General(extension, "wk_heg__weiwenzhugezhi", "wu", 4)
local mingchao = fk.CreateActiveSkill{
  name = "wk_heg__mingchao",
  anim_type = "special",
  prompt = function(self)
    return "#wk_heg__mingchao"
  end,
  interaction = function(self)
    return UI.ComboBox { choices = {"wk_heg__mingchao_show" .. Self:getMark("@@wk_heg__mingchao_exchange") .. ":::" .. Self:usedSkillTimes(self.name) + 1, "wk_heg__mingchao_discard" .. Self:getMark("@@wk_heg__mingchao_exchange") .. ":::" .. Self:usedSkillTimes(self.name) + 1} }
  end,
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    if self.interaction.data:startsWith("wk_heg__mingchao_discard") then
      return Fk:getCardById(to_select):getMark("@@wk_heg__mingchao_shown-inhand-turn") == 0 and not Self:prohibitDiscard(to_select)
    else
      return Fk:getCardById(to_select):getMark("@@wk_heg__mingchao_shown-inhand-turn") == 0
    end
  end,
  target_filter = Util.FalseFunc,
  card_num = function(self)
    return Self:usedSkillTimes(self.name) + 1
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    if not self.interaction.data then return end
    local player = room:getPlayerById(effect.from)
    local card = effect.cards
    if self.interaction.data:startsWith("wk_heg__mingchao_show") then
      player:showCards(card)
      for _, id in ipairs(card) do
        room:setCardMark(Fk:getCardById(id), "@@wk_heg__mingchao_shown-inhand-turn", 1)
      end
      if player:getMark("@@wk_heg__mingchao_exchange") == 0 then
        local to = player
        if not to:isKongcheng() then
          local extra_data = {bypass_times = true}
          local availableCards = {}
          for _, id in ipairs(card) do
            local card = Fk:getCardById(id)
            if not player:prohibitUse(card) and player:canUse(card, extra_data) then
              table.insertIfNeed(availableCards, id)
            end
          end
          -- 摆，直接偷观骨view_as函数用
          local use = U.askForUseRealCard(room, player, availableCards, ".", self.name, "#wk_heg__dingjian-use", {extra_use = true}, true)
          if use then
            room:useCard(use)
          end
        end
      else
        player:drawCards(1, self.name)
        room:setPlayerMark(player, "@@wk_heg__mingchao_exchange", 0)
      end
    else
      room:throwCard(card, self.name, player, player)
      if player:getMark("@@wk_heg__mingchao_exchange") == 0 then
        player:drawCards(1, self.name)
        room:setPlayerMark(player, "@@wk_heg__mingchao_exchange", 1)
      else
        -- 摆，直接偷定谏函数用
        local to_use = {}
        to_use = table.filter(card, function (id)
          local card = Fk:getCardById(id)
          return room:getCardArea(id) == Card.DiscardPile and not player:prohibitUse(card)
        end)
        if #to_use > 0 then
          local use = U.askForUseRealCard(room, player, to_use, ".", self.name, "#wk_heg__dingjian-use", {expand_pile = to_use, extra_use = true}, true)
          if use then
            room:useCard(use)
          end
        end
      end
    end
  end,
}

weiwenzhugezhi:addSkill(mingchao)
Fk:loadTranslationTable{
  ["wk_heg__weiwenzhugezhi"] = "卫温诸葛直",
  ["#wk_heg__weiwenzhugezhi"] = "谜络长洲",
  ["designer:wk_heg__weiwenzhugezhi"] = "祭祀",
  ["wk_heg__mingchao"] = "鸣潮",
  [":wk_heg__mingchao"] = "出牌阶段，你可以选择一项：1.展示X张此回合未展示的牌，然后<u>使用其中一张牌</u>" ..
  "；2.弃置X张此回合未展示的牌，然后<u>摸一张牌并交换选项效果</u>（即每个选项中“然后”后面的文字效果，也即下划线部分）。（X为此回合发动此技能次数+1）",

  ["@@wk_heg__mingchao_shown-inhand-turn"] = "鸣潮",
  ["@@wk_heg__mingchao_exchange"] = "鸣潮 交换效果",
  ["wk_heg__mingchao_show0"] = "展示%arg张牌，然后使用其中一张牌",
  ["wk_heg__mingchao_show1"] = "展示%arg张牌，然后摸一张牌并交换选项效果",
  ["wk_heg__mingchao_discard0"] = "弃置%arg张牌，然后摸一张牌并交换选项效果",
  ["wk_heg__mingchao_discard1"] = "弃置%arg张牌，然后使用其中一张牌",
  ["#wk_heg__mingchao"] = "鸣潮：你可以展示或弃置此回合未展示过的牌，然后执行对应效果",

  ["$wk_heg__mingchao1"] = "宦海沉浮，生死难料！",
  ["$wk_heg__mingchao2"] = "跨海南征，波涛起浮。",
  ["~wk_heg__weiwenzhugezhi"] = "吾皆海岱清士，岂料生死易逝……",
}

local yuantanyuanshang = General(extension, "wk_heg__yuantanyuanshang", "qun", 4)
local neifa = fk.CreateViewAsSkill{
  name = "wk_heg__neifa",
  anim_type = "special",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:getCardById(to_select):compareColorWith(Fk:getCardById(selected[1]), true)
    else
      return false
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then
      return nil
    end
    local c = Fk:cloneCard("fight_together")
    c.skillName = self.name
    c:addSubcards(cards)
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("wk_heg__neifa-turn") == 0
  end,
}

local neifa_effect = fk.CreateTriggerSkill{
  name = "#wk_heg__neifa_effect",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("wk_heg__neifa_damage") == 1 and player.chained and data.card and table.contains(data.card.skillNames, "wk_heg__neifa")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return p.chained end), Util.IdMapper)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#wk_heg__neifa-choose")
      if #tos > 0 then
        local to = room:getPlayerById(tos[1])
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = self.name,
        }
      end
    end
    room:setPlayerMark(player, "wk_heg__neifa_damage", 0)
  end,

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    return data.card and table.contains(data.card.skillNames, "wk_heg__neifa")
      and (not table.find(TargetGroup:getRealTargets(data.tos), function(id) return not room:getPlayerById(id).chained end) or not player.chained)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if not table.find(TargetGroup:getRealTargets(data.tos), function(id) return not room:getPlayerById(id).chained end) then
      room:setPlayerMark(player, "wk_heg__neifa-turn", 1)
    end
    if not player.chained then
      room:setPlayerMark(player, "wk_heg__neifa_damage", 1)
    end
  end,
}

neifa:addRelatedSkill(neifa_effect)
yuantanyuanshang:addSkill(neifa)
Fk:loadTranslationTable{
  ["wk_heg__yuantanyuanshang"] = "袁谭袁尚",
  ["#wk_heg__yuantanyuanshang"] = "兄弟阋墙",
  ["designer:wk_heg__yuantanyuanshang"] = "静谦",
  ["wk_heg__neifa"] = "内伐",
  [":wk_heg__neifa"] = "你可将两张颜色不同的牌当【勠力同心】使用，此牌结算后若你因此横置，你可以对一名横置的角色造成1点伤害，若没有角色因此横置，此技能失效至本回合结束。",

  ["$wk_heg__neifa1"] = "自相恩残，相煎何急。",
  ["$wk_heg__neifa2"] = "同室内伐，贻笑外人。",
  ["~wk_heg__yuantanyuanshang"] = "",
}

return extension

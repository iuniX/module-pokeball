local BALLS_OPCODE = 166

local p_pokemonsInfo = {}
local p_pokeballTopMenuButton
local p_pokeballsWindow
local p_pokemonsList

local _parseStartReceiveData
local _parseReceiveData
local _parseFinishReceiveData

function init()
  p_pokeballTopMenuButton = modules.client_topmenu.addRightGameButton('pokeballButton', tr('Used Pokeballs'), 'images/button', toggle, true)

  p_pokeballsWindow = g_ui.loadUI('pokeballs', rootWidget)
  p_pokemonsList = p_pokeballsWindow:getChildById('pokemonsList')
  
  g_game.handleExtended(BALLS_OPCODE, receiveData)
  connect(g_game, { onGameEnd = hide})
end

function terminate() 
  disconnect(g_game, {onGameEnd = hide})
  g_game.unhandleExtended(BALLS_OPCODE, receiveData)
  p_pokeballsWindow:destroy()
  p_pokeballTopMenuButton:destroy()
end

function show()
  p_pokeballsWindow:show()
  p_pokeballsWindow:raise()
  p_pokeballsWindow:focus()
end

function hide()
  p_pokeballsWindow:hide()
end

function toggle()
  if p_pokeballsWindow:isVisible() then
    p_pokeballsWindow:hide()
  else
    g_game.sendExtended(BALLS_OPCODE, "open")
  end
end

function receiveData(t)  
  if t == 1 then
    _parseStartReceiveData()
  elseif t == 2 then
    _parseFinishReceiveData()
  else
    _parseReceiveData(t)
  end
end

function _parseStartReceiveData()
  p_pokemonsInfo = {}
  show()
  toggleLoading(true)
end

function _parseReceiveData(t)
  for _,info in ipairs(t) do
    local pokeInfo = {}
    pokeInfo.id = info[1]
    pokeInfo.balls = info[2]
    pokeInfo.shinyId = info[3] or 0
    pokeInfo.name = info[4]
    pokeInfo.price = info[5]
    pokeInfo.waste = info[6]

    pokeInfo.total = 0
    for _, value in pairs(pokeInfo.balls) do
      pokeInfo.total = pokeInfo.total + value
    end

    table.insert(p_pokemonsInfo, pokeInfo)
  end
  refreshData("id", "asc")
end

function _parseFinishReceiveData()
  toggleLoading(false)
end

function toggleLoading(show)
  local loadingPanel = p_pokeballsWindow:getChildById("loadingPanel")
  loadingPanel:setVisible(show)
  p_pokeballsWindow:getChildById("searchText"):setEnabled(not show)
end

function refreshData(orderType, sortOrder)
  if not sortOrder then
    if p_pokemonsList.orderType == orderType then
      sortOrder = p_pokemonsList.sortOrder == "asc" and "desc" or "asc"
    else
      sortOrder = "asc"
    end
  end

  if sortOrder == "desc" then
    table.sort(p_pokemonsInfo, function(a, b) return a[orderType] > b[orderType] end)
  else
    table.sort(p_pokemonsInfo, function(a, b) return a[orderType] < b[orderType] end)
  end
 
  p_pokemonsList:destroyChildren()
  for _, value in ipairs(p_pokemonsInfo) do
    addData(value)
  end

  p_pokemonsList.orderType = orderType
  p_pokemonsList.sortOrder = sortOrder
end

function addData(data)
  local currentPokemon = g_ui.createWidget('PokemonData', p_pokemonsList)

  local id = string.format("%03d", data.id)
  if data.shinyId > 0 then
    id = id .. "." .. data.shinyId
  end

  local image = currentPokemon:getChildById("dataImage")
  image:setImageSource("/game_pokedex/pokemons/" .. id)
  image:setTooltip(tr("Npc Price: $%d\nTotal Spent: $%d", data.price, data.waste))
  
  currentPokemon:getChildById("dataName"):setText(data.name)
  currentPokemon:getChildById("dataNumber"):setText("#".. string.format("%03d", data.id))
  currentPokemon:getChildById("dataTotal"):setText(data.total)

  local pokeballsPanel = currentPokemon:getChildById("dataPokeballs")
  local showAllCheckBox = p_pokeballsWindow:getChildById("showAllCheckBox")
  for ballID = 1,18 do
    local currentPokeball = g_ui.createWidget('PokeballWidget', pokeballsPanel)
    local pbImage = currentPokeball:getChildById("pokeballImage")
    pbImage:setImageSource("images/pb" .. ballID)
    local balls = data.balls[ballID] or 0
    currentPokeball:getChildById("pokeballCount"):setText(balls)

    if not showAllCheckBox:isChecked() and balls == 0 then
      currentPokeball:setVisible(false)
    end
  end
end

function onSearchTextChange(text)
  text = string.lower(text)

  for _,pokemonWidget in ipairs(p_pokemonsList:getChildren()) do
    local nameWidget = pokemonWidget:getChildById("dataName")
    local match = #text == 0 or string.find(string.lower(nameWidget:getText()), text)
    pokemonWidget:setVisible(match)
  end
end

function onShowAllChecked(showAll)
  if not p_pokemonsList then
    return
  end

  for _,pokemonWidget in ipairs(p_pokemonsList:getChildren()) do
    local pokeballsPanel = pokemonWidget:getChildById("dataPokeballs")
    for _,pokeballWidget in ipairs(pokeballsPanel:getChildren()) do
      local count = tonumber(pokeballWidget:getChildById("pokeballCount"):getText())
      pokeballWidget:setVisible(showAll or count > 0)
    end
  end
end

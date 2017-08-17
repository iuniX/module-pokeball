local BALLS_OPCODE = 166

local p_pokemonsInfo = {}
local p_pokeballsWindow
local p_pokemonsList
local p_preSortType
local p_sortOrder
local p_loadingPanel

local p_pokeballTopMenuButton
local _startWindow


function init()
  p_pokeballTopMenuButton = modules.client_topmenu.addRightGameButton('pokeballButton', tr('Contador de Pokeballs'), 'images/button', toggle, true)

  p_pokeballsWindow = g_ui.displayUI('pokeballs')
  
  p_pokemonsList = p_pokeballsWindow:getChildById('pokemonsList')
  p_loadingPanel = p_pokeballsWindow:getChildById("loadingPanel")
  showAllCheckBox = p_pokeballsWindow:getChildById("showAllCheckBox")
  connect(showAllCheckBox, {onCheckChange = onShowAllChecked()})
  showAllCheckBox:setChecked(true)
  p_preSortType = "id"
  p_sortOrder = "asc"
  
  g_game.handleExtended(BALLS_OPCODE, receiveData)  
  connect(g_game, { onGameEnd = hide})
  
  hide()
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

function toggle (var)
  if p_pokeballsWindow:isVisible() then
    p_pokeballsWindow:hide()
  else
    g_game.sendExtended(BALLS_OPCODE, "open")
  end
end

function receiveData(t)  
  if type(t) == "number" then
    if t == 1 then
      p_pokemonsInfo = {}
      show()
      toggleLoading(true)
      return
    end
    toggleLoading(false)
    return
  end

  local currentIndex = #p_pokemonsInfo

  for i = 1,#t do
    local info = t[i]
    local special = info[3] or 0
    currentIndex = currentIndex + 1
    p_pokemonsInfo[currentIndex] = {}
    p_pokemonsInfo[currentIndex].balls = info[2]
    p_pokemonsInfo[currentIndex].id = info[1]
    p_pokemonsInfo[currentIndex].special = special
    p_pokemonsInfo[currentIndex].name = info[4]
    p_pokemonsInfo[currentIndex].total = 0
    p_pokemonsInfo[currentIndex].price = info[5]
    p_pokemonsInfo[currentIndex].waste = info[6]

    for ballID, value in pairs(p_pokemonsInfo[currentIndex].balls) do
      p_pokemonsInfo[currentIndex].total = p_pokemonsInfo[currentIndex].total + value
    end
  end
  refreshData() 
end

function toggleLoading(show)
  p_loadingPanel:setVisible(show)
  p_pokeballsWindow:getChildById("searchText"):setEnabled(not show)
end

function refreshData(orderType)
  if p_pokemonsList then
    cleanPokemons()
    
    local reverse = false 
    if not p_preSortType then
      p_preSortType = "id"
    end
  
    if not orderType then 
      orderType = p_preSortType
    else
      reverse = (p_preSortType == orderType) and (p_sortOrder == "asc")
    end

    if reverse then
      table.sort(p_pokemonsInfo, function( a,b ) return a[orderType] > b[orderType] end )
    else
      table.sort(p_pokemonsInfo, function( a,b ) return a[orderType] < b[orderType] end )
    end
   
    for _, value in ipairs(p_pokemonsInfo) do
       addData(value)
    end
    
    if reverse then
      p_sortOrder = "desc"
    else
      p_sortOrder = "asc"
    end
    p_preSortType = orderType
    
  end
end

function addData(data)
  if data.total == 0 then
    return
  end

  local currentPokemon = g_ui.createWidget('PokemonData', p_pokemonsList)
  currentPokemon:setId(data.name)

  local id = string.format("%03d", data.id)

  if data.special > 0 then
    id = tostring(id .. "." .. data.special)
  end

  local image = currentPokemon:getChildById("dataImage")
  image:setImageSource("/game_pokedex/pokemons/" .. id)
  image:setTooltip(tr("Npc Price: $") .. data.price .. tr("\nTotal Spent: $") .. data.waste)
  
  currentPokemon:getChildById("dataName"):setText(data.name)
  currentPokemon:getChildById("dataNumber"):setText("#".. string.format("%03d", data.id))
  currentPokemon:getChildById("dataTotal"):setText(data.total)

  for ballID = 1,18 do
    if showAllCheckBox:isChecked() or data.balls[ballID] then
      local pokeballsPanel = currentPokemon:getChildById("dataPokeballs")
      local currentPokeball = g_ui.createWidget('PokeballWidget', pokeballsPanel)
      currentPokeball:setId(ballID)
      local pbImage = currentPokeball:getChildById("pokeballImage")
      pbImage:setImageSource("images/pb" .. ballID)
      local balls = data.balls[ballID] or 0
      currentPokeball:getChildById("pokeballCount"):setText(balls)   
   end
  end
end

function onSearchTextChange(text)
  if #text <= 0 then return refreshData() end
  cleanPokemons()
  text = string.lower(text)
  for _, value in ipairs(p_pokemonsInfo) do
    if string.find(string.lower(value.name), text) then
      addData(value)
    end
  end
end

function cleanPokemons()
  if p_pokemonsList then
    local children = p_pokemonsList:recursiveGetChildren()
    for _, child in ipairs(children) do
      child:destroy()
    end
  end
end

function onShowAllChecked()
  cleanPokemons()
  for _, value in ipairs(p_pokemonsInfo) do
    addData(value)
  end
end

PokeballCount = { }
local BALLS_OPCODE = 166

PokemonsInfo = {}
pokeballsWindow = nil
pokemonsList = nil
pokemonsListScrollBar = nil
pageButton = nil
currentPage = nil
pageCount = nil
preSortType = nil
sortOrder = nil
loadingPanel = nil


local p_pokeballTopMenuButton
local _startWindow

function init()
  p_pokeballTopMenuButton = modules.client_topmenu.addRightGameButton('pokeballButton', tr('Contador de Pokeballs'), 'images/button', toggle, true)

  pokeballsWindow = g_ui.displayUI('pokeballs')
  
  pokemonsList = pokeballsWindow:getChildById('pokemonsList')
  pokemonsListScrollBar = pokeballsWindow:getChildById('pokemonsListScrollBar')
  loadingPanel = pokeballsWindow:getChildById("loadingPanel")
  showAllCheckBox = pokeballsWindow:getChildById("showAllCheckBox")
  connect(showAllCheckBox, {onCheckChange = _onCheck})
  showAllCheckBox:setChecked(true)
  preSortType = "id"
  sortOrder = "asc"

  
  g_game.handleExtended(BALLS_OPCODE, receiveData)  
  connect(g_game, { onGameEnd = hide})
  
  hide()
end

function terminate() 
  disconnect(g_game, {onGameEnd = hide})
  g_game.unhandleExtended(BALLS_OPCODE, receiveData)
  pokeballsWindow:destroy()
  p_pokeballTopMenuButton:destroy()
end

function toggle (var)
  if pokeballsWindow:isVisible() then
    pokeballsWindow:hide()
  else
    g_game.sendExtended(BALLS_OPCODE, 'z')
  end
end

function receiveData(t)  
  if type(t) == "number" then
    if t == 1 then
      PokemonsInfo = {}
      show()
      toggleLoading(true)
      return
    end
    toggleLoading(false)
    return
  end

  local currentIndex = #PokemonsInfo

  for i = 1,#t do
    local info = t[i] 
    local special = info[3] or 0
    local currentID = info[1]
    currentIndex = currentIndex + 1
    PokemonsInfo[currentIndex] = {}
    PokemonsInfo[currentIndex].balls = info[2]
    PokemonsInfo[currentIndex].id = currentID + (0.1*special)
    PokemonsInfo[currentIndex].special = special
    PokemonsInfo[currentIndex].name = info[4]
    PokemonsInfo[currentIndex].total = 0
    PokemonsInfo[currentIndex].price = info[5]
    PokemonsInfo[currentIndex].waste = info[6]

    for ballID, value in pairs(PokemonsInfo[currentIndex].balls) do
      PokemonsInfo[currentIndex].total = PokemonsInfo[currentIndex].total + value
    end
  end
  refreshData() 
end

function toggleLoading(show)
  loadingPanel:setVisible(show)
  pokeballsWindow:getChildById("searchText"):setEnabled(not show)
end

function refreshData(orderType)
  if pokemonsList then
    cleanPokemons()
    
    local reverse = false 
    if not preSortType then
      preSortType = "id"
    end
  
    if not orderType then 
      orderType = preSortType
    else
      reverse = (preSortType == orderType) and (sortOrder == "asc")
    end

    if reverse then
      table.sort(PokemonsInfo, function( a,b ) return a[orderType] > b[orderType] end )
    else
      table.sort(PokemonsInfo, function( a,b ) return a[orderType] < b[orderType] end )
    end
   
    for _, value in ipairs(PokemonsInfo) do
       addData(value)
    end
    
    if reverse then
      sortOrder = "desc"
    else
      sortOrder = "asc"
    end
    preSortType = orderType
    
  end
end

function addData(data)
  if data.total == 0 then
    return
  end

  local currentPokemon = g_ui.createWidget('PokemonData', pokemonsList)
  currentPokemon:setId(data.name)
  local numberString = ""  

  if data.id < 100 then
    numberString = "0" .. numberString
  end
  
  if data.id < 10 then
    numberString = "0" .. numberString
  end
            
  local imagem = currentPokemon:getChildById("dataImage")
  imagem:setImageSource("/game_pokedex/pokemons/" .. numberString .. data.id)
  imagem:setTooltip("Npc Price: $" .. data.price .. "\nTotal Spent: $" .. data.waste)
  
  if data.special then
    numberString = numberString .. (data.id - (0.1*data.special))
  else
    numberString = numberString .. data.id 
  end
  
  currentPokemon:getChildById("dataName"):setText(data.name)
  currentPokemon:getChildById("dataNumber"):setText("#".. numberString)
  currentPokemon:getChildById("dataTotal"):setText(data.total)

  for ballID = 1,18 do
    if showAllCheckBox:isChecked() then
      local pokeballsPanel = currentPokemon:getChildById("dataPokeballs")
      local currentPokeball = g_ui.createWidget('PokeballWidget', pokeballsPanel)
      currentPokeball:setId(ballID)
      local pbImage = currentPokeball:getChildById("pokeballImage")
      pbImage:setImageSource("images/pb" .. ballID)
      local balls = data.balls[ballID]
      if not balls then
        balls = 0
      end
      currentPokeball:getChildById("pokeballCount"):setText(balls)   
    else
      if data.balls[ballID] then
        local pokeballsPanel = currentPokemon:getChildById("dataPokeballs")
        local currentPokeball = g_ui.createWidget('PokeballWidget', pokeballsPanel)
        currentPokeball:setId(ballID)
        local pbImage = currentPokeball:getChildById("pokeballImage")
        pbImage:setImageSource("images/pb" .. ballID)
        currentPokeball:getChildById("pokeballCount"):setText(data.balls[ballID])
      end
    end
  end
end

function hide()
  pokeballsWindow:hide()
end

function show()
  pokeballsWindow:show()
  pokeballsWindow:raise()
  pokeballsWindow:focus()
end

function onSearchTextChange(text)
  if #text <= 0 then return refreshData() end
  local results = {}
  cleanPokemons()
  for _, value in ipairs(PokemonsInfo) do
    if string.find(string.lower(value.name), string.lower(text)) then
      addData(value)
    end
  end
end

function cleanPokemons()
  if pokemonsList then
    local children = pokemonsList:recursiveGetChildren()
    for _, child in ipairs(children) do
      child:destroy()
    end
  end
end

function _onCheck()
  cleanPokemons()
  for _, value in ipairs(PokemonsInfo) do
    addData(value)
  end
end
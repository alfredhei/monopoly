##--------------------------------------------------------------------------------
## FUNCTIONS v.0.4.R
## Contains the game-functions.
##--------------------------------------------------------------------------------

##--------------------------------------------------------------------------------
## Housekeeping: Importing libraries and sources the strategies-script. 
##--------------------------------------------------------------------------------
source('strategies v0.4.R')
library(dplyr)

##--------------------------------------------------------------------------------
## throwDice: Simulates the throwing of two dice.
## output: Returns an integer between 2 and 12. 
##--------------------------------------------------------------------------------
throwDice <- function(){
  dice <- c(sample(1:6, size = 1, replace = TRUE), sample(1:6, size = 1, replace = TRUE))
  return(dice)
  ##SLETT??
  #simuler kast m/ 2 terninger, se hist nedenfor for bevis 
  #hist(replicate(1000, sample(1:6, size = 1, replace = TRUE) + sample(1:6, size = 1, replace = TRUE)))
  #hist(replicate(100000, sum(sample(1:6, size = 2, replace = TRUE))))
  
}

##--------------------------------------------------------------------------------
## move: Handles the changing the position of the players on the board, by altering board-dataframe.
## input: x = number given by dice throw
## -  Increments position variable of player by what is given by the dices. 
## -  Handles discontinuity at Go and also handles adding $ to balance of players when passing Go. 
##--------------------------------------------------------------------------------
move <- function(x){
  cur_position <- players$position[cur_player]
  if(cur_position + x > nrow(board)){
    y <- nrow(board) - cur_position
    players$position[cur_player] <<- x - y
    players$fortune[cur_player] <<- players$fortune[cur_player] + roundCap
    ##SLETT??
    #cat(sprintf("Player %s moved %s tiles to position %s, and passed Go.",cur_player, x, x-y))
  }
  else{
    if(players$jailDays[cur_player] == 1){
      players$jailDays[cur_player] <<- players$jailDays[cur_player] - 1
      players$position[cur_player] <<- cur_position + x
      #cat(sprintf("Player %s KOM UT AV GPA TIIID",cur_player))
    }
    if(players$jailDays[cur_player] %in% c(2,3)){
      players$jailDays[cur_player] <<- players$jailDays[cur_player] - 1
      #cat(sprintf("Player %s I FENGSEL MINUS EN RUNDE %s",cur_player, cur_position))
    }
    if(players$jailDays[cur_player] == 0){
      players$position[cur_player] <<- cur_position + x
    }
    
    ##SLETT??
    #cat(sprintf("Player %s moved %s tiles to position %s",cur_player, x, cur_position + x))
  }
} 


##--------------------------------------------------------------------------------
## processPos: Handles actions and consequences of moving to a tile.
## -  If the tile is not a property, the player will be subject to an automatic action 
##    (which can be no action at all if the tile is blank).
## -  If the property is owned by someone else the player that landed on the tile has to pay a toll. 
##    A seperate function deals with the specifics of paying. 
## -  If the person cannot afford a free property nothing happens and the turn moves to the next player.
## -  If the player lands on a tile, that is a property, is free and he can afford. 
##--------------------------------------------------------------------------------

processPos <- function(){#håndter posisjon for spiller cur_player, leder til flere sub-funksjoner
  position <<- players$position[cur_player]
  if(board$prop[position] %in% c(1,2,3,4)){
      if(board$owner[position] == 0){ #sjekk om ledig
        if(board$price[position] <= players$fortune[cur_player]){ #sjekk om råd
          #kjør strategi
          runStrategy()
        }else{
          #ikke råd
        }
      }else{
        owner <<- board$owner[position]
        processNames <- c("Prop", "Util", "Train")
        strategyName <- paste("process", processNames[board$prop[position]], sep="")
        if(owner != cur_player){
          get(strategyName)()
        }
      }
  }
  if(board$prop[position] %in% c(0,5,6)){
    processNames <- c("Jail", "Auto", "Free")
    strategyName <- paste("process", processNames[match(board$prop[position],c(0,5,6))], sep="")
    get(strategyName)()
  }
  #check if player owns all of a color
  uniqueC <- unique(board$color[board$color != "" & board$color != "white" & board$color != "grey"])
  ownsAll <<- c() #liste over farger hvor cur_player eier alle, gitt av for løkken nedenfor
  for (i in 1:length(uniqueC)) {
    if(checkStreetPer(uniqueC[i], cur_player) == TRUE){
      ownsAll <<- c(ownsAll, i)
    }
  }
 
  if(length(ownsAll) == 1){ #hvis en spiller eier alle av en farge/farger
    #print("ALFRED")
    housesInCol <- board$houses[board$color == uniqueC[ownsAll[1]]]
    sQuery <- board$position[board$color == uniqueC[ownsAll[1]] & board$houses == min(housesInCol) & board$houses < 5]
    if(length(sQuery) != 0){
      wTB <- max(sQuery)
      if(players$fortune[cur_player] - board$housePrice[board$position == wTB] > 0){
        propPrice <<- board$housePrice[board$position == wTB]
        strategyName <- paste("strategy", players$strategy[cur_player], sep="")
        if(get(strategyName)("HOUSE") == TRUE){ #KJØPER BARE HUS OM TRUE FRA STRATEGI
          board$houses[board$position == wTB] <<- board$houses[board$position == wTB] + 1 
          players$fortune[cur_player] <<- players$fortune[cur_player] - board$housePrice[board$position == wTB]
          gatherStat("house", 1)
          #print("KJØPT HUS")
        }else{
          gatherStat("house", 0)
        }
      }
    }
  }
  if(length(ownsAll) > 1){ #hvis en spiller eier alle av en farge/farger
    colFocus <- sample(1:length(ownsAll), 1)
    housesInCol <- board$houses[board$color == uniqueC[ownsAll[colFocus]]]
    sQuery <- board$position[board$color == uniqueC[ownsAll[colFocus]] & board$houses == min(housesInCol) & board$houses < 5]
    if(length(sQuery) != 0){
      wTB <- max(sQuery)
      if(players$fortune[cur_player] - board$housePrice[board$position == wTB] > 0){
        propPrice <<- board$housePrice[board$position == wTB]
        strategyName <- paste("strategy", players$strategy[cur_player], sep="")
        if(get(strategyName)("HOUSE") == TRUE){
          board$houses[board$position == wTB] <<- board$houses[board$position == wTB] + 1 
          players$fortune[cur_player] <<- players$fortune[cur_player] - board$housePrice[board$position == wTB]
          gatherStat("house", 1)
          #print("KJØPT HUS")
        }else{
          gatherStat("house", 0)
        }    
      }
    }
  }
} 

##--------------------------------------------------------------------------------
## processFree: 
##--------------------------------------------------------------------------------
processFree <- function(){
  
}

##--------------------------------------------------------------------------------
## processJail: 
##--------------------------------------------------------------------------------
processJail <- function(){
  if(board$position[position] == 30){
    players$position[cur_player] <<- 9 #teleporter til jail
    players$jailDays[cur_player] <<- 3 #kommer ut på 3. runden
    #cat(sprintf("Player %s moved to jail",cur_player))
    #for å holde spilleren i jail trenger vi et element i df for å se om just visiting eller i jail
    #  og for å se hvor mange kast spilleren har forsøkt å komme ut
  }
  if(board$position[position] == 10){
    dice1 <- sample(1:6, size = 1, replace = TRUE)
    dice2 <- sample(1:6, size = 1, replace = TRUE)
    if(dice1 == dice2){
      players$jailDays[cur_player] <<- 0
      move(dice1 + dice2)
      #cat(sprintf("Player %s KOM UT AV FENGSEL PGA TERNINGKAST",cur_player))
    }
    #cat(sprintf("Player %s KOM ikkkkke UT AV FENGSEL PGA TERNINGKAST",cur_player))
     #teleporter til jail
    #for å holde spilleren i jail trenger vi et element i df for å se om just visiting eller i jail
    #  og for å se hvor mange kast spilleren har forsøkt å komme ut
  }
}

##--------------------------------------------------------------------------------
## processAuto: 
##--------------------------------------------------------------------------------
processAuto <- function(){
  players$fortune[cur_player] <<- players$fortune[cur_player] - board$autopay[position]
  #cat(sprintf("AUTOPAY, spiller %s betaler %s til %s", cur_player, board$autopay[position], board$name[position]))
}

##--------------------------------------------------------------------------------
## processUtil: 
##--------------------------------------------------------------------------------
processUtil <- function(){
  NoT <- nrow(board[board$prop  == "2" & board$owner == owner,]) #hvor mange tog eieren av dette toget eier
  utilR <- c(4, 10) #multipliers for landing on a util
  dice_res <- sum(throwDice()) #kast terning
  players$fortune[owner] <<- players$fortune[owner] + dice_res*utilR[NoT] #formelen for tog-leie er 25*2^(x-1). D gir rekken 1,2,4,8. drd en ganger 25 m/ for å få leieprisene 25,50,100,200
  players$fortune[cur_player] <<- players$fortune[cur_player] - dice_res*utilR[NoT]
  #cat(sprintf("UTILITY, spiller %s eier %s util, spiller %s kastet %s og betaler %s   ", owner, NoT, cur_player, dice_res, dice_res*utilR[NoT]))
}

##--------------------------------------------------------------------------------
## processTrain: 
##--------------------------------------------------------------------------------
processTrain <- function(){
  NoT <- nrow(board[board$prop  == "3" & board$owner == owner,]) #hvor mange tog eieren av dette toget eier
  players$fortune[owner] <<- players$fortune[owner] + board$rent[position]*2^(NoT-1) #formelen for tog-leie er 25*2^(x-1). D gir rekken 1,2,4,8. drd en ganger 25 m/ for å få leieprisene 25,50,100,200
  players$fortune[cur_player] <<- players$fortune[cur_player] - board$rent[position]*2^(NoT-1)
  #cat(sprintf("TOOG, spiller %s eier %s tog, spiller %s betaler %s", owner, NoT, cur_player, board$rent[position]*2^(NoT-1)))
}

##--------------------------------------------------------------------------------
## processProp: 
##--------------------------------------------------------------------------------
processProp <- function(){
  #sjekke om den som eier gaten også eier alle i samme farge
  color <<- as.character(board$color[position])
  if(checkStreetPer(color, owner) == TRUE){
    #en annen spiller en den som landet her eier alle av denne fargen, dobbel leie
    if(board$houses[position] > 0){
      housesFunc <- sprintf("rent%sh", board$houses[position])
      players$fortune[owner] <<- players$fortune[owner] + board[[housesFunc]][position]
      players$fortune[cur_player] <<- players$fortune[cur_player] - board[[housesFunc]][position]
      #cat(sprintf("HUSLEIE, spiller %s fikk %s for %s", owner, board[[housesFunc]][position], board$name[position]))
    }else{
      players$fortune[owner] <<- players$fortune[owner] + board$rent[position]*2
      players$fortune[cur_player] <<- players$fortune[cur_player] - board$rent[position]*2
      #print("DOBBEL LEIE")
    }

    #cat(sprintf("DOBBEL, spiller %s eier hele %s", owner, board$color[position]))
  }else{
    players$fortune[owner] <<- players$fortune[owner] + board$rent[position]
    players$fortune[cur_player] <<- players$fortune[cur_player] - board$rent[position]
    #print("LEIE")
  }
  
}

#sjekk om alle farger blir eid av én spiller
checkStreetPer <- function(x, y){
  NoC <- nrow(board[board$color  == x,]) #hvor mange gater i den fargen
  NoCo <- nrow(board[board$color  == x & board$owner == y,]) 
  if(NoC == NoCo){
    return(TRUE)
  }else{
    return(FALSE)
  }
}

##--------------------------------------------------------------------------------
## checkPlayerLoss: Checks to see if player has lost by seeing if balance is negative. 
##--------------------------------------------------------------------------------
checkPlayerLoss <- function(){#sjekk hvis cur_player har tapt
  if(players$fortune[cur_player] < 0){
    players$active[cur_player] <<- 0
    board2 <<- board
    board <<- board %>%
      mutate(houses=replace(houses, owner==cur_player, 0)) %>%
      mutate(owner=replace(owner, owner==cur_player, 0)) %>%
      as.data.frame()
    #cat(sprintf("Player %s ran out of cash!", cur_player))
    return(TRUE)
    ##SLETT??

  }else{
    return(FALSE)
  }
}

##--------------------------------------------------------------------------------
## checkGameOver: Checks to see if game is over, by checking how many players remain in game. 
## -  Sets game_over to true and sets match_winner to be the only remaining player, also records player's strategy. 
##--------------------------------------------------------------------------------
checkGameOver <- function(){
  if(length(players$active[players$active==TRUE])==1){
    game_over <<- TRUE
    winner <<- players$id[players$active==TRUE]
    winnerS <<- players$strategy[players$active==TRUE]
    
    ##SLETT??
    print(winner)
    #cat(sprintf("Player %s won, using strategy %s", winner, winnerS))
  }
} 

##--------------------------------------------------------------------------------
## setNextPlayer: Handles player's turn-taking.
## -  Sets cur_player to next player in player-dataframe, unless we're at the last player, 
##    then circle back to player 1.
##--------------------------------------------------------------------------------
setNextPlayer <- function(){
  if(cur_player == N){
    cur_player <<- 1
  } else {
    cur_player <<- cur_player + 1
  }
  
  ##SLETT??
  #cat(sprintf("Player %s's turn",cur_player))
}

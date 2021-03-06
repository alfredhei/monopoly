##---------------------------------------------------------
## Monopoly Simulation - Main script
## Version 0.4
##---------------------------------------------------------

#NB pass på variabler: globale = << og lokale = <
#NB test enkeltfunksjoner fra dette dokumentet, ikke 'functions vx.x.R'


initGame <- function(){
  #require(neuralnet)
  #nn strategi 100, ser på sammenheng mellom seier og [posisjon, saldo, ant. hus, ant eiendommer]
  #nn=neuralnet(X1~X5+X1500+X0+X0.1,data=logForNN, hidden=0,act.fct = "logistic", linear.output = FALSE, stepmax=1e6)
  #nn strategi 101, ser på sammenheng mellom seier og [ant. hus, ant eiendommer]
  #nn=neuralnet(X1~X3+X0,data=logForNN2, hidden=1,act.fct = "logistic", linear.output = FALSE, stepmax=1e6)
  #nn strategi 102, ser på sammenheng mellom seier og [ant. hus pr farge, ant eiendommer pr farge]
  #nn=neuralnet(win~brown+lblue+purple+orange+red+yellow+green+blue+brownhouses+lbluehouses+purplehouses+orangehouses+redhouses+yellowhouses+greenhouses+bluehouses,data=logForNN3, hidden=c(10,10, 10, 10, 10),act.fct = "logistic", linear.output = FALSE, stepmax=1e6)
  #nn strategi 103, ser på sammenheng mellom seier og [ant. hus pr farge, ant eiendommer pr farge]
  #nn=neuralnet(win~throws+fortune+brown+lblue+purple+orange+red+yellow+green+blue+brownhouses+lbluehouses+purplehouses+orangehouses+redhouses+yellowhouses+greenhouses+bluehouses+buyStreet+buyHouse,data=logForNN4, hidden=c(3,2),act.fct = "logistic", linear.output = FALSE, stepmax=1e4, lifesign="full")
  
  #plot(nn)
  #------------------------- Settings --------------------------
  setwd("../v0.4")              # Set working directory to correct version number
  N <<- 2                       # N = Number of player
  strategy <- c(sample(1:9, 1), sample(1:9, 1)) # Set player strategies, first parameter sets strategy for player 1, etc...
  #strategy <- c(sample(1:9, 1), sample(1:9, 1), sample(1:9, 1), sample(1:9, 1))
  startCap <- 1500              # Sets start capital for all players.
  roundCap <<- 200              # Capital gained frmo passing 'Go'.
  version <- 4                  # Sets game version.
  bid_Active <<- TRUE           # Turn bidding on and off.
  #-------------------------------------------------------------
  
  logForNN4temp <<- data.frame(matrix(NA, 0, 21))
  id <- c(1:N) #som vektor til data.frame
  throws <<- rep(0, times=N)
  fortune <<- rep(startCap, times=N)
  nHouses <<- rep(0, times=N)
  nProps <<- rep(0, times=N)
  active <- rep(1, times=N) #sett spillere som er aktive, alle v/ init
  position <- rep(1, times=N) #tile 1 er start
  jailDays <- rep(0, times=N) #tile 1 er start
  players <<- data.frame(id, strategy, fortune, active, position, jailDays, throws) #data.frame m/ oversikt over spillerne
}

##---------------------------------------------------------
## Main-function.
##---------------------------------------------------------
#logForNN <- data.frame()
startGame <- function(){
  source("functions v0.4.R")
  library(ggplot2)
  board <<- read.csv("monopoly_data v0.4.csv") #importer/reset gameboard som data.frame
  
  initGame()                      # Reset verdier for spillet(start på nytt)
  cur_player <<- sample(1:N, 1)   # Selects initial player at random. Eliminates potential first-mover (dis)advantage.
  game_over <<- FALSE
  ptm <- Sys.time()  #Timer
  while (game_over == FALSE) { #loop så lenge ikke én er vinnner
    av_dices <<- 1 #available dice throws, pga to like = nytt kast..
    equalDicesQount <<- 0 #sjekke hvor mange ganger på rad to like, hvis over tre -> fengsel
    while (av_dices >= 1 & players$active[cur_player] == 1) {
      av_dices <<- av_dices - 1
      dice_res <- throwDice() #kast terning og lagre resultat
      if(length(unique(dice_res)) == 1){
        av_dices <<- av_dices + 1
        equalDicesQount <<- equalDicesQount + 1
        #print("SLO TO LIKE")
      }
      if(equalDicesQount > 2){
        av_dices <<- 0
        equalDicesQount <<- 0
        players$position[cur_player] <<- 9 #teleporter til jail
        players$jailDays[cur_player] <<- 3 #kommer ut på 3. runden
        #print("to like tre ganger = fengsel")
      }else{
        move(sum(dice_res)) #endre position for cur_player i players data.frame
        processPos() #håndter posisjon for spiller cur_player, leder til flere sub-funksjoner
      }
      if(checkPlayerLoss() == TRUE){
        av_dices <<- 0
      } #sjekk hvis cur_player har tapt
    }
    
    ################################################################
    ############# Samler inn statistikk for runden.  ###############
    ################################################################
    
    players$throws[cur_player] <<- players$throws[cur_player] + 1
    
    
    # Samler inn fortune-data.
    fortune <<- cbind(fortune, players$fortune)
    
    # Samler inn eiendoms-data.
    curProps <- rep(0, N)
    for (i in 1:N) {
      curProps[i] <- length(board$owner[(board$owner==i) & !(is.na(board$owner))])
    }
    nProps <<- cbind(nProps, curProps)
    
    # Samler inn hus-data.
    curHouses <- rep(0, N)
    for (i in 1:N) {
      sumHouses <- sum(board$houses[(board$owner==i) & !(is.na(board$owner))  & !(is.na(board$houses))])
      # sumHouses <- board %>%
      #   filter(owner==i) %>%
      #   summarize(sum(houses))
      curHouses[i] <- sumHouses
    }
    nHouses <<- cbind(nHouses, curHouses)
    
    ################################################################
    #############    Slutt: Statistikkinnsamling     ###############
    ################################################################
    
    checkGameOver() #sjekk om spillet er over
    setNextPlayer() #endre cur_player til neste
    ptm2 <- Sys.time() - ptm
    #timeout funskjon for å forhindre krasj
    if(ptm2 > 4){
      cat(sprintf("time out %s",Sys.time()))
      players$active[players$id != players$id[players$fortune == max(players$fortune)]] <<- 0
      players$active[players$id == players$id[players$fortune == max(players$fortune)]] <<- 0
      checkGameOver()
      game_over <- TRUE
    }

    
  }


  
  
  ##PRINTFUNKSJON FOR FORTUNE-UTVIKING
  fortune <- t(data.frame(fortune))
  colnames(fortune)[1:N] <- paste(sprintf("player%s", 1:ncol(fortune)))

  

  ################################################################
  ############## PRINTFUNKSJON FOR FORTUNE-UTVIKING ##############
  ##############            MED GGPLOT              ##############
  ################################################################

  ##SLETT??
  # fortune <- data.frame(fortune)
  # fortune <- t(data.frame(fortune))
  # colnames(fortune)[1:N] <- paste(sprintf("player%s", 1:ncol(fortune)))

  fortune <- data.frame(fortune)
  fortune %>% 
    ggplot() +
    geom_line(aes(x = 1:nrow(fortune), y = fortune[,1]), color="blue") +
    geom_line(aes(x = 1:nrow(fortune), y = fortune[,2]), color="red") +
    #geom_line(aes(x = 1:nrow(fortune), y = fortune[,3]), color="orange") +
    #geom_line(aes(x = 1:nrow(fortune), y = fortune[,4]), color="green") +
    scale_color_manual(values = c("#00AFBB", "#E7B800")) +
    theme_minimal()
  ################################################################
  #############        SLUTT FORTUNE-PRINT         ###############
  ################################################################
}

startGame()

################################################################
#############           START NN DATA             ###############
################################################################

#write.csv(logForNN,'logForNN3.csv')
#logForNN <<- data.frame(matrix(NA, 0, 5))
#logForNN2 <<- data.frame(matrix(NA, 0, 5))
#logForNN3 <<- data.frame(matrix(NA, 0, 17))

#logForNN4 <<- data.frame(matrix(NA, 0, 24))

replicate(200, buildDataBaseforNN())
replicate(20, buildDataBaseforNN2())
replicate(200, buildDataBaseforNN3())

replicate(100, buildDataBaseforNN4())

buildDataBaseforNN <- function(){
  startGame()
  for(y in 1:N){
    #cat(sprintf("N: %s \n", y))
    bol <- as.numeric(fortune[y,][seq(1, length(fortune[y,]), 5)])
    dola <- as.numeric(nProps[y,][seq(1, length(nProps[y,]), 5)])
    aola <- as.numeric(nHouses[y,][seq(1, length(nHouses[y,]), 5)])
    cola <- c()
    wola <- c(rep(players$active[y], times=length(bol)))
    #cat(sprintf("length bol: %s \n", length(bol)))
    for(j in 1:length(bol)){
      #cat(sprintf("j: %s \n", j*5))
      logForNN <<- rbind(logForNN, c(j*5, bol[j], dola[j], aola[j], wola[j]))
    }
    #logForNN <<- matrix(cola, bol, dola, wola, ncol = 5, nrow = length(bol))
  }
  colnames(logForNN) <- c("throws", "saldo", "streets", "houses", "win")
}

buildDataBaseforNN2 <- function(){
  startGame()
  for(y in 1:N){
    #cat(sprintf("N: %s \n", y))
    #bol <- as.numeric(fortune[y,][seq(1, length(fortune[y,]), 5)])
    dola <- max(nProps[y,][seq(1, length(nProps[y,]), 5)])
    aola <- max(nHouses[y,][seq(1, length(nHouses[y,]), 5)])
    wola <- c(players$active[y])

    logForNN2 <<- rbind(logForNN2, c(dola, aola, wola))
    #logForNN <<- matrix(cola, bol, dola, wola, ncol = 5, nrow = length(bol))
  }
  #colnames(logForNN2) <- c("throws", "saldo", "streets", "houses", "win")
}
buildDataBaseforNN3 <- function(){
  startGame()
  for(y in 1:N){
    
    uniqueC <- unique(board$color[board$color != "" & board$color != "white" & board$color != "grey"])
    streetColFreq <<- c()
    houseColFreq <<- c()
    for (i in 1:length(uniqueC)) {
      NoC <- nrow(board2[board$color  == uniqueC[i],]) #hvor mange gater i den fargen
      NoCo <- nrow(board2[board$color  == uniqueC[i] & board2$owner == y,]) 
      streetColFreq <<- c(streetColFreq, NoCo)
      
      sumHouses <- sum(board2$houses[(board2$owner==y) & !(is.na(board2$owner))  & !(is.na(board2$houses)) & board2$color  == uniqueC[i]])
      houseColFreq <<- c(houseColFreq, sumHouses)
    }
    wola <- c(players$active[y])
    
    logForNN3 <<- rbind(logForNN3, c(streetColFreq, houseColFreq, wola))
  }
  colnames(logForNN3) <- c(as.character(uniqueC), as.character(paste(uniqueC, "houses", sep = '')), "win")
}

buildDataBaseforNN4 <- function(){
  startGame()
  logForNN4temp <<- logForNN4temp %>%
    mutate(win = ifelse(id == winner, 1, 0))
  logForNN4 <<- rbind(logForNN4, logForNN4temp)
    
  colnames(logForNN4) <- c("throws", "fortune", as.character(uniqueC), as.character(paste(uniqueC, "houses", sep = '')), "buyStreet", "buyHouse", "id", "win")
}

################################################################
#############          SLUTT NN DATA             ###############
################################################################

# #---------------
# #Mål hvor mange runder spillet går
# #---------------
# #lengde <<- c()
# #replicate(100, startGame())
# #mean(lengde)
# #lengde <- lengde[lengde<=200]
# #hist(lengde, breaks=20, xlim=c(0,360))
# lengde <<- c()
# replicate(100, startGame())
# hist(lengde, breaks=20, xlim=c(0,360), ylim = c(0,20))
# ## TESTING FOR Å FÅ UT VERDIER PÅ HVILKEN STRATEGI SOM ER BEST
plot(nn)
k=50
winners = 1:k*0
numberOfRounds <- 1:k*0
# 
for (i in 1:k) {
  startGame()
  #buildDataBaseforNN()
  winners[i] <- winner
}

hist(winners)
table(winners)
# 
# pbinom(73, size = 100, prob = 0.5)
# 
# ## Number of rounds
# hist(numberOfRounds, breaks=60)
# 
# ##Plot the results!!!
# plot(x=1:length(fortune1), y = fortune1, ylim=c(0, max(c(fortune1, fortune2))))
# lines(x=1:length(fortune2), y = fortune2)
# print("number of props")
# print(length(board$owner[board$owner==1]))
# print(length(board$owner[board$owner==2]))

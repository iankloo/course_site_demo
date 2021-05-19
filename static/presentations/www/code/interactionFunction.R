treatmentCombos <- function(vec, out = NULL, leaveOutBase = TRUE){
  if(length(vec) > 0){
    
    if(is.null(out)){
      combo <- vec[1]
      newVec <- vec[-1]
      treatmentCombos(newVec, out = combo)
    } else{
      doneTmp <- out
      combo <- append(out, vec[1])
      combo <- append(combo, unlist(lapply(doneTmp, FUN = function(d) paste(d, vec[1], sep = ''))))
      newVec <- vec[-1]
      treatmentCombos(newVec, out = combo)
    }
    
  } else{
    if(leaveOutBase){
      return(out)
    } else{
      return(c('(1)',out))
    }
  }
}


buildTreatments <- function(myFactors){
  lfactors <- tolower(myFactors)
  n <- 1:(length(lfactors))
  
  treatment <- treatmentCombos(lfactors)
  #treatments <- data.frame(treatment = unlist(lapply(n, FUN = function(d) apply(combn(lfactors, d), 2, FUN = function(f) paste(f, collapse = '')))), stringsAsFactors = FALSE)
  tmp <- lapply(lfactors, function(d) unlist(lapply(treatment, FUN = function(e) ifelse(d %in% unlist(strsplit(e, "")), 1, -1))))
  
  tmpDF <- data.frame(do.call(cbind, tmp))
  colnames(tmpDF) <- toupper(myFactors)
  
  out <- cbind(treatment, tmpDF)
  tmpNull <- out[1,]
  tmpNull[,] <- -1
  tmpNull$treatment <- '(1)'
  out <- rbind(tmpNull, out)
  
  return(out)
}


makeInteractionGrid <- function(myData, nonFactorCols = c('treatment')){
  cols <- colnames(myData)
  cols <- cols[!cols %in% nonFactorCols]
  
  n <- 2:(length(cols))
  
  interNames <- unlist(lapply(n, FUN = function(d) apply(combn(cols, d), 2, FUN = function(f) paste(f, collapse = ''))))
  
  for(i in interNames){
    myData[,i] <- apply(myData[, unlist(strsplit(i,''))], 1, FUN = prod)
  }
  
  return(myData)
}

getEffects <- function(myData, obsColName = 'obs', nonFactorCols = c('treatment'), stErrorEst = NULL, keep = NULL, fractional = NULL){
  cols <- colnames(myData)
  cols <- cols[!cols %in% c(obsColName, nonFactorCols)]
  
  lens <- unlist(lapply(cols, FUN = function(d) length(unlist(strsplit(d, '')))))
  numMainEffects <- sum(lens[lens == 1])
  
  effectVec <- unlist(lapply(cols, FUN = function(d) sum(myData[,d] * myData[,obsColName]) * (1 / (2^(numMainEffects-1)))))
  
  effectDF <- data.frame(term = cols, effect = effectVec, stringsAsFactors = FALSE)
  if(is.null(fractional) == FALSE){
    effectDF$effect <- effectDF$effect*(1/fractional)
  }
  effectDF$coefficient <- effectDF$effect/2
  
  effectDF <- rbind(data.frame(term = 'Constant', effect = NA, coefficient = mean(myData[,obsColName])), effectDF)
  
  if(is.null(keep) == FALSE) stErrorEst <- cols[!cols %in% keep]
  
  if(is.null(stErrorEst) == FALSE){
    
    anovaTable <- data.frame(term = effectDF$term[effectDF$term != 'Constant'], stringsAsFactors = FALSE)
    anovaTable <- cbind(anovaTable, data.frame(SS = unlist(lapply(cols, FUN = function(d) (sum(myData[,d] * myData[,obsColName])^2) / (2^numMainEffects) ))))
    
    anovaTable$DF <- 1
    
    anovaTable <- rbind(anovaTable, data.frame(term = 'Error', SS = sum(anovaTable$SS[anovaTable$term %in% stErrorEst]), DF = length(stErrorEst)))
    
    anovaTable <- anovaTable[!anovaTable$term %in% stErrorEst,]
    
    anovaTable$MS <- anovaTable$SS / anovaTable$DF
    
    anovaTable$F <- anovaTable$MS / anovaTable$MS[anovaTable$term == 'Error']
    anovaTable$F[anovaTable$term == 'Error'] <- NA
    
    anovaTable$P <- NA
    
    anovaTable$P <- mapply(FUN = function(x,y) pf(abs(x), df1 = y, df2 = anovaTable$DF[anovaTable$term == 'Error'], lower.tail = FALSE),
                           anovaTable$F, anovaTable$DF)
    
    effectDF$SE <- sqrt(anovaTable$MS[anovaTable$term == 'Error'] * (1/(2^numMainEffects)))
    if(is.null(fractional) == FALSE){
      effectDF$SE <- effectDF$SE*(1/fractional)
    }
    
    effectDF$t <- effectDF$coefficient / effectDF$SE
    
    effectDF$P <- pt(abs(effectDF$t), df = nrow(myData) - (nrow(effectDF)-1), lower.tail = FALSE) * 2
    if(is.null(fractional) == FALSE){
      effectDF$P <- pt(abs(effectDF$t), df = (nrow(myData)*(1/fractional)) - ((nrow(effectDF)*(1/fractional))-1), lower.tail = FALSE) * 2
    }
    
    effectDF <- effectDF[!effectDF$term %in% stErrorEst,]
    
    return(list(effects = effectDF, anova = anovaTable))
  } else {
    return(effectDF)
  }
}
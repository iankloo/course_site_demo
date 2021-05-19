library(data.table)

source(file = "interactionFunction.R")
TC <- treatmentCombos(vec = c("a", "b", "c", "d", "e", "f", "g"))
df <- buildTreatments(myFactors =  c("A", "B", "C", "D", "E", "F", "G"))
df <- makeInteractionGrid(myData = df)

tcs <- c("def", "afg", "beg", "abd", "cdg", "ace", "bcf", "abcdefg", "abcg", "bcde", "acdf",
         "cefg", "abef", "bdfg", "adeg", "(1)") # add the remaining treatment combinations
design_tcs <- match(tcs, df$treatment) # this returns the row numbers of the TCs

z <- list() # create an empty list to fill in the loop below
# The loop below returns the column name (effect) for all columns that are all +1s for the subsetted design matrix
for (i in seq_along(2:length(colnames(df)))) {
  z[i-1] <-  ifelse(identical(df[ design_tcs , i ] , rep(1, 2^(7-3))), colnames(df[i]), NA)
}
def_rel <- unlist(z[!is.na(z)])
def_rel

ali <- function(dr, e) {
  ifelse(e %in% unlist(strsplit(dr, split = "")),
         paste(unlist(strsplit(dr, split = ""))[!(unlist(strsplit(dr, split = "")) %in% e)],collapse=""),
         paste0(dr, e))
}

# "A" %in% unlist(strsplit("ABCG", split = ""))
# unlist(strsplit("ABCG", split = ""))[!(unlist(strsplit("ABCG", split = "")) %in% "A")]
# paste0("ABCG", "F")
ali("ABCG","A") #drops "A"
# ali(dr= "ABCG", e="F") # adds "F"

aliases <- function(dr, e) {
  lapply(dr, ali, e)
}

z <- lapply(colnames(df[2:8]), aliases, dr=def_rel) #takes each main effect and finds the alias from each defining relation
z <- rbindlist(z)
rownames(z) <- colnames(df[2:8])
z

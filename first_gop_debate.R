
Skip to content
This repository

Pull requests
Issues
Marketplace
Gist

@AGARNER18

0
0

0

AGARNER18/First-GOP-Debate
Code
Issues 0
Pull requests 0
Projects 0
Wiki
Settings
First-GOP-Debate/R code
b9c9429 13 days ago
@AGARNER18 AGARNER18 Update R code
461 lines (383 sloc) 20.5 KB
library(ibmdbR)
mycon <- idaConnect("BLUDB", "", "")
idaInit(mycon)

DEBATE <- as.data.frame(ida.data.frame('"DASH103769"."V_DEBATE"')[ ,c('CANDIDATE', 'CANDIDATE_CONFIDENCE', 'CANDIDATE_GOLD', 'EMOTION', 'ID', 'NAME', 'RETWEET_COUNT', 'SENTIMENT', 'SENTIMENT_CONFIDENCE', 'SENTIMENT_GOLD', 'SUBJECT_MATTER', 'SUBJECT_MATTER_CONFIDENCE', 'SUBJECT_MATTER_GOLD', 'TEXT', 'TWEET_ID')])

# make sure table was loaded correctly
summary(DEBATE)
dim(DEBATE)
str(DEBATE)
# find missing values in each variable
apply(is.na(DEBATE),2,sum)

#*****************************DATA PREPROCESSING********************************************************
# remove variables where all or most of the values are missing
DEBATE$CANDIDATE_GOLD<-NULL
DEBATE$SENTIMENT_GOLD<-NULL
DEBATE$SUBJECT_MATTER_GOLD<-NULL
DEBATE$TWEET_ID<-NULL

# look at the 16 rows where CANDIDATE is null
DEBATE[is.na(DEBATE$CANDIDATE),c(4,11)]
# only 16 are missing so the appropriate candidate replaced the missing value by ID
DEBATE$CANDIDATE[DEBATE$ID %in% c('2929', '5307', '6644', '1023', '3667', '7785', '2641', '3985')]<-'No candidate mentioned'
DEBATE$CANDIDATE[DEBATE$ID %in% c('37','4076','3012','1653','2206')]<-'Donald Trump'
DEBATE$CANDIDATE[DEBATE$ID %in% c('7425', '9474','10893')]<-'Scott Walker'
# verify that there are no loner missing values 
DEBATE[is.na(DEBATE$CANDIDATE),c(3,11)]

# look at the 34 missing values in subject matter
DEBATE[is.na(DEBATE$SUBJECT_MATTER),c(4,11)]
table(as.factor(DEBATE$SUBJECT_MATTER))
DEBATE$SUBJECT_MATTER[DEBATE$ID %in% c('1341', '7756')]<-'Religion'
DEBATE$SUBJECT_MATTER[DEBATE$ID %in% c('6644')]<-'Gun Control'
DEBATE$SUBJECT_MATTER[DEBATE$ID %in% c('1624', '1653', '9504', '4076', '8513', '1817')]<-'FOX News or Moderators'
DEBATE$SUBJECT_MATTER[DEBATE$ID %in% c('6962')]<-'Abortion'
# change the missing to None of the above because they all fall into that category
DEBATE$SUBJECT_MATTER[is.na(DEBATE$SUBJECT_MATTER)]<-'None of the above'
# verify that there are no longer missing values
DEBATE[is.na(DEBATE$SUBJECT_MATTER),c(4,11)]

# remove remaining 2 rows with missing values in retween count and name column
DEBATE<-DEBATE[complete.cases(DEBATE),]
# verify there are no missing values left
apply(is.na(DEBATE),2,sum)

# convert to appropriate data type
attach(DEBATE)
DEBATE$CANDIDATE<-as.factor(CANDIDATE)
DEBATE$CANDIDATE_CONFIDENCE<-as.numeric(CANDIDATE_CONFIDENCE)
DEBATE$SENTIMENT<-as.factor(SENTIMENT)
DEBATE$EMOTION<-as.factor(EMOTION)
DEBATE$SENTIMENT_CONFIDENCE<-as.numeric(SENTIMENT_CONFIDENCE)
DEBATE$SUBJECT_MATTER<-as.factor(SUBJECT_MATTER)
DEBATE$SUBJECT_MATTER_CONFIDENCE<-as.numeric(SUBJECT_MATTER_CONFIDENCE)

# get all rows where sentiment is negative and emotion is joy
joy_neg<-DEBATE[DEBATE$SENTIMENT %in% 'Negative'& DEBATE$EMOTION %in% 'joy',]

# change all the sentiment in joy_neg to positive
joy_neg$SENTIMENT<-'Positive'

# get all rows where sentiment is any combination except negative and joy
everything_else<-DEBATE[(DEBATE$SENTIMENT %in% c('Positive', 'Neutral') & DEBATE$EMOTION %in% c('anger','disgust','fear','sadness','surprise','unknown', 'joy')) | DEBATE$SENTIMENT %in% 'Negative' & DEBATE$EMOTION %in% c('anger','disgust','fear','sadness','surprise','unknown'),]

# combine rows where the sentiment was changed and everything else
DEBATE<-rbind(joy_neg, everything_else)

# verify that sentiment is still a factor data type
DEBATE$SENTIMENT<-as.factor(SENTIMENT)

# get only the text
some_txt = DEBATE$TEXT

# look at text before cleaning
some_txt[15]

# remove unnecessary spaces
some_txt = gsub("[ \t]{2,}", "", some_txt)
some_txt = gsub("^\\s+|\\s+$", "", some_txt)

# remove retweet
some_txt = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", some_txt)

# remove at people
some_txt = gsub("@\\w+", "", some_txt)

# remove punctuation
some_txt = gsub("[[:punct:]]", "", some_txt)

# remove numbers
some_txt = gsub("[[:digit:]]", "", some_txt)

# remove html links
some_txt = gsub("http\\w+", "", some_txt)

# remove unnecessary spaces
some_txt = gsub("[ \t]{2,}", "", some_txt)
some_txt = gsub("^\\s+|\\s+$", "", some_txt)

# define "tolower error handling" function 
try.error = function(x)
{
  # create missing value
  y = NA
  # tryCatch error
  try_error = tryCatch(tolower(x), error=function(e) e)
  # if not an error
  if (!inherits(try_error, "error"))
    y = tolower(x)
  # result
  return(y)
}
# lower case using try.error with sapply 
some_txt = sapply(some_txt, try.error)

# replace words that have the same meaning and need to be counted as one
some_txt = gsub("debates", "debate", some_txt)
some_txt = gsub("stands", "stand", some_txt)
some_txt = gsub("primaries", "primary", some_txt)
some_txt = gsub("votes", "vote", some_txt)
some_txt = gsub("tedcruz", "cruz", some_txt)
some_txt = gsub("donaldtrump", "trump", some_txt)
some_txt = gsub("hilaryclinton", "clinton", some_txt)

# remove NAs in some_txt
some_txt = some_txt[!is.na(some_txt)]
names(some_txt) = NULL

# look at text after cleaning
some_txt[15]

#Replace full stop and comma
sentences<-gsub("\\.","",some_txt)
sentences<-gsub("\\,","",some_txt)

# transform into a data frame
# try without this: sentences.df<-as.data.frame(sentences)

# Split sentences into words
words<-strsplit(sentences," ")
words <- unlist(words)

# get word frequencies using the table function
words.freq<-table(words)

#convert to data frame
words.df<-as.data.frame(words.freq)

# look at the data frame to verify it is correct
head(words.df)

# look at most frequent words
head(words.df[order(words.df$Freq, decreasing=TRUE), ], 50) # most of the top words are common words so they need to be removed for this to be valuable

# remove stopwords 
# gopdebate removed because doesn't add value 
words.rem<-words.df[ ! words.df$words %in% c("gopdebate","gopdebates","did", "ask","said","im","just","i", "amp","a", "about", "above", "above", 
                                             "across", "after", "afterwards", "again", "against", "all", "almost", "alone", "along", "already", 
                                             "also","although","always","am","among", "amongst", "amoungst", "amount",  "an", "and", "another", 
                                             "any","anyhow","anyone","anything","anyway", "anywhere", "are", "around", "as",  "at", "back","be",
                                             "became", "because","become","becomes", "becoming", "been", "before", "beforehand", "behind", "being", 
                                             "below", "beside", "besides", "between", "beyond", "bill", "both", "bottom","but", "by", "call", "can", 
                                             "cannot", "cant", "co", "con", "could", "couldnt", "cry", "de", "describe", "detail", "do", "done", "down", 
                                             "due", "during", "each", "eg", "eight", "either", "eleven","else", "elsewhere", "empty", "enough", "etc", 
                                             "even", "ever", "every", "everyone", "everything", "everywhere", "except", "few", "fifteen", "fify", "fill", 
                                             "find", "fire", "first", "five", "for", "former", "formerly", "forty", "found", "four", "from", "front", 
                                             "full", "further", "get", "give", "go", "had", "has", "hasnt", "have", "he", "hence", "her", "here", "hereafter", 
                                             "hereby", "herein", "hereupon", "hers", "herself", "him", "himself", "his", "how", "however", "hundred", "ie", 
                                             "if", "in", "inc", "indeed", "interest", "into", "is", "it", "its", "itself", "keep", "last", "latter", "latterly",
                                             "least", "less", "ltd", "made", "many", "may", "me", "meanwhile", "might", "mill", "mine", "more", "moreover", 
                                             "most", "mostly", "move", "much", "must", "my", "myself", "name", "namely", "neither", "never", "nevertheless", 
                                             "next", "nine", "no", "nobody", "none", "noone", "nor", "not", "nothing", "now", "nowhere", "of", "off", "often",
                                             "on", "once", "one", "only", "onto", "or", "other", "others", "otherwise", "our", "ours", "ourselves", "out", 
                                             "over", "own","part", "per", "perhaps", "please", "put", "rather", "re", "same", "see", "seem", "seemed", "seeming", 
                                             "seems", "serious", "several", "she", "should", "show", "side", "since", "sincere", "six", "sixty", "so", "some", 
                                             "somehow", "someone", "something", "sometime", "sometimes", "somewhere", "still", "such", "system", "take", "ten", 
                                             "than", "that", "the", "their", "them", "themselves", "then", "thence", "there", "thereafter", "thereby", "therefore", 
                                             "therein", "thereupon", "these", "they", "thickv", "thin", "third", "this", "those", "though", "three", "through", 
                                             "throughout", "thru", "thus", "to", "together", "too", "top", "toward", "towards", "twelve", "twenty", "two", "un", 
                                             "under", "until", "up", "upon", "us", "very", "via", "was", "we", "well", "were", "what", "whatever", "when", "whence", 
                                             "whenever", "where", "whereafter", "whereas", "whereby", "wherein", "whereupon", "wherever", "whether", "which", "while", 
                                             "whither", "who", "whoever", "whole", "whom", "whose", "why", "will", "with", "within", "without", "would", "yet", "you", 
                                             "your", "yours", "yourself", "yourselves", "the"), ]
#***********************************WORD FREQUENCY*****************************************

# view most frequent words after stop words were removed
head(words.rem[order(words.rem$Freq, decreasing=TRUE), ], 70) # much better

# create new variable sorted for nicer plot
words.rem.sorted<-words.rem[order(words.rem$Freq, decreasing=TRUE), ]

library(ggplot2)
# frequency plot of words with frequency more than 25
p<-ggplot(subset(words.rem.sorted, Freq>20), aes(reorder(words, -Freq),Freq))
p<-p+ geom_bar(stat="identity", colour="black", fill="royalblue")
p<-p+ ggtitle("Frequency of Words")
p<-p+ theme(axis.text.x = element_text(angle=45, hjust = 1, size=18), axis.title=element_text(size=14,face="bold"))
p<-p+ labs(x="Words", y="Frequency")
all_freq_plot<-p
all_freq_plot

# get a list of the words in the plot becausde plot is a bit fuzzy
words.rem.sorted[words.rem.sorted$Freq>30,]

#********************************ASSOCIATION RULES*****************************************
str(DEBATE)

# look at the distribution
hist(DEBATE$CANDIDATE_CONFIDENCE)
# discretize for association analysis
DEBATE$CANDIDATE_CONFIDENCE<-discretize(as.numeric(DEBATE$CANDIDATE_CONFIDENCE), method="interval")
# look at the result
summary(DEBATE$CANDIDATE_CONFIDENCE)

# look at the distribution
hist(DEBATE$RETWEET_COUNT)
DEBATE$RETWEET_COUNT<-cut(DEBATE$RETWEET_COUNT, breaks=c(0,1,2,4416),right=FALSE, include.lowest = TRUE)
summary(DEBATE$RETWEET_COUNT)

# look at the distribution
hist(DEBATE$SENTIMENT_CONFIDENCE)
DEBATE$SENTIMENT_CONFIDENCE<-cut(as.numeric(DEBATE$SENTIMENT_CONFIDENCE), breaks=c(0,0.5,1),right=FALSE, include.lowest = TRUE)
summary(DEBATE$SENTIMENT_CONFIDENCE)

# look at the distribution
hist(DEBATE$SUBJECT_MATTER_CONFIDENCE)
DEBATE$SUBJECT_MATTER_CONFIDENCE<-discretize(as.numeric(DEBATE$SUBJECT_MATTER_CONFIDENCE), method="interval", categories = 3)
summary(DEBATE$SUBJECT_MATTER_CONFIDENCE)

# subset to only include the variables useful for analysis
DEBATE_FACTOR<-DEBATE[,c(1:3,6:10)]

library(arules)
library(arulesViz)

#**********basic association mining

# find association rules with apriori
rules <- apriori(DEBATE_FACTOR, parameter = list(supp = 0.3, conf = 0.6, target = "rules"))
# see number of rules generated
rules
# look at the rules
inspect(rules)
# sort the rules according to lift
rules.sorted <- sort(rules, by="lift")
inspect(rules.sorted)
# look at sorted rules
inspect(rules.sorted)

# find the redundant rules
subset.matrix <- is.subset(rules.sorted, rules.sorted)
subset.matrix[lower.tri(subset.matrix, diag=T)] <- NA
redundant <- colSums(subset.matrix, na.rm=T) >= 1
which(redundant)

# remove redundant rules
rules.pruned <- rules.sorted[!redundant]
inspect(rules.pruned)
# plot results
plot(rules.pruned, method = "matrix", measure = "lift")
# bubble chart of the rules
plot(rules.pruned, method = "grouped", control = list(k = 20, col=heat.colors(100), main="First GOP Debate/nSentiment Analysis"))


#****Association mining without emotion unknown

# remove rows where Candidate is No candidate mentioned and confidence variables
DEBATE_CAN<-DEBATE_FACTOR[DEBATE_FACTOR$EMOTION!='unknown',]
# remove confidence variables
DEBATE_CAN<-DEBATE_CAN[,c(1,3,4,5,7)]
# find association rules with apriori where right hand side is sentiment 
rules <- apriori(DEBATE_CAN, parameter = 
                   list(supp = 0.2, conf = 0.4, target = "rules"))

# see number of rules generated                
rules
# look at the rules
inspect(rules)
# sort the rules according to lift
rules.sorted <- sort(rules, by="lift")
inspect(rules.sorted)

# find the redundant rules
subset.matrix <- is.subset(rules.sorted, rules.sorted)
subset.matrix[lower.tri(subset.matrix, diag=T)] <- NA
redundant <- colSums(subset.matrix, na.rm=T) >= 1
which(redundant)

# remove redundant rules
rules.pruned <- rules.sorted[!redundant]
rules.pruned
inspect(rules.pruned)

#*****Assocition rules without no candidate mentioned, none of the above, and unknown

# remove rows where Candidate is No candidate mentioned
DEBATE_CAN<-DEBATE_FACTOR[(DEBATE_FACTOR$EMOTION!='unknown'& DEBATE$CANDIDATE!='No candidate mentioned' & DEBATE$SUBJECT_MATTER!='None of the above'),]
# remove confidence variables
DEBATE_CAN<-DEBATE_CAN[,c(1,3,4,5,7)]
# find association rules with apriori where right hand side is sentiment 
rules <- apriori(DEBATE_CAN, parameter = 
                   list(supp = 0.15, conf = 0.95, target = "rules"))

# see number of rules generated                
rules
# look at the rules
inspect(rules)
# sort the rules according to lift
rules.sorted <- sort(rules, by="lift")
inspect(rules.sorted)

# find the redundant rules
subset.matrix <- is.subset(rules.sorted, rules.sorted)
subset.matrix[lower.tri(subset.matrix, diag=T)] <- NA
redundant <- colSums(subset.matrix, na.rm=T) >= 1
which(redundant)

# remove redundant rules
rules.pruned <- rules.sorted[!redundant]
rules.pruned
inspect(rules.pruned)
# plot results
plot(rules.pruned, method = "matrix", measure = "lift")
# bubble chart of the rules
plot(rules.pruned, method = "grouped", control = list(k = 20, col=heat.colors(100), main="First GOP Debate/nSentiment Analysis"))
# sort the rules according to lift

#*****Association mining for just Trump on the right hand side without unknown, no candidate mentioned, and none of the above
# find association rules with apriori where right hand side is sentiment 
rules <- apriori(DEBATE_CAN, parameter = 
                   list(supp = 0.1, conf = 0.1, target = "rules"), list(rhs=("CANDIDATE=Donald Trump"),
                                                                        default="lhs"))

# see number of rules generated                
rules
# look at the rules
inspect(rules)
# sort the rules according to lift
rules.sorted <- sort(rules, by="lift")
inspect(rules.sorted)


# plot results
plot(rules.sorted, method = "matrix", measure = "lift")
# bubble chart of the rules
plot(rules.sorted, method = "grouped", control = list(k = 20, col=heat.colors(100), main="First GOP Debate/nSentiment Analysis"))
# sort the rules according to lift

#********************************************************RPART**********************************************
# build an rpart decision tree to predict the sentiment using all the variables as predictors except text and id
debate.fit <- rpart(SENTIMENT ~ CANDIDATE 
                    + CANDIDATE_CONFIDENCE 
                    + RETWEET_COUNT 
                    + EMOTION
                    + SENTIMENT_CONFIDENCE 
                    + SUBJECT_MATTER
                    + SUBJECT_MATTER_CONFIDENCE
                    , data = DEBATE)
# look at the results of the decision tree
debate.fit

pred = predict(debate.fit, type="class")
table(pred)
table(pred, DEBATE$SENTIMENT)

sample.df<-DEBATE[DEBATE$SENTIMENT %in% 'Negative',]
other<-DEBATE[DEBATE$SENTIMENT %in% c('Positive','Neutral'),]
sample<-sample.df[sample(nrow(sample.df), 300), ]
debate.sampled<-rbind(sample, other)

# build an rpart decision tree to predict the sentiment using all the variables as predictors except text and id
debate.fit2 <- rpart(SENTIMENT ~ CANDIDATE 
                     + CANDIDATE_CONFIDENCE 
                     + EMOTION 
                     + RETWEET_COUNT
                     + SENTIMENT_CONFIDENCE 
                     + SUBJECT_MATTER
                     + SUBJECT_MATTER_CONFIDENCE
                     , data = debate.sampled)
# look at the results of the decision tree
debate.fit2

pred = predict(debate.fit2, type="class")
table(pred)
table(pred, debate.sampled$SENTIMENT)
# create a simple plot of the decision tree
plot(debate.fit, )
text(debate.fit, pretty=0.5)

# create a nicer plot of the decision tree
rpart.plot(debate.fit2, type = 4,extra=104, 
           main="FIRST GOP DEBATE", cex=12)

#********************************************************NAVIE BAYES*********************************************
install.packages("e1071")
library(e1071)
debate.bayes <- naiveBayes(SENTIMENT ~ CANDIDATE 
                           + CANDIDATE_CONFIDENCE 
                           + EMOTION
                           + RETWEET_COUNT 
                           + SENTIMENT_CONFIDENCE 
                           + SUBJECT_MATTER
                           + SUBJECT_MATTER_CONFIDENCE
                           , data = DEBATE)
summary(debate.bayes)
print(debate.bayes)
DEBATE2<-DEBATE[,c(1,2,5,6,7,8,9,10)]
table(predict(debate.bayes, DEBATE2[,-5]), DEBATE2[,5])

sample.df<-DEBATE[DEBATE$SENTIMENT %in% 'Negative',]
other<-DEBATE[DEBATE$SENTIMENT %in% c('Positive', 'Neutral'),]
sample<-sample.df[sample(nrow(sample.df), 300), ]
debate.sampled<-rbind(sample, other)
debate.bayes <- naiveBayes(SENTIMENT ~ CANDIDATE 
                           + CANDIDATE_CONFIDENCE 
                           + EMOTION
                           + RETWEET_COUNT 
                           + SENTIMENT_CONFIDENCE 
                           + SUBJECT_MATTER
                           + SUBJECT_MATTER_CONFIDENCE
                           , data = debate.sampled)
summary(debate.bayes)
DEBATE2<-debate.sampled[,c(1,2,5,6,7,8,9,10)]
table(predict(debate.bayes, DEBATE2[,-5]), DEBATE2[,5])


#*****************************************************VISUALIZATION***********************************************

# bar plot of sentiment and retweet count by candidate
p<-ggplot(data=subset(DEBATE, DEBATE$CANDIDATE != 'No candidate mentioned'), aes(x=CANDIDATE, y=RETWEET_COUNT, fill=SENTIMENT))
p<- p + geom_bar(stat="identity")
p<- p + scale_fill_manual(values=c('#cc0000','#0099cc', '#009933'))
p<-p+ theme(axis.text.x = element_text(angle=45, hjust = 1, size=18), axis.title=element_text(size=14,face="bold"))
p<-p+ ggtitle("Sentiment and Retweet by Candidate")
p<-p+ labs(x="Candidates", y="Number of Retweets")
p

# bar plot of sentiment and retweet count by candidate
p<-ggplot(data=subset(DEBATE, DEBATE$CANDIDATE != 'No candidate mentioned' & DEBATE$EMOTION != 'unknown'), aes(x=CANDIDATE, y=RETWEET_COUNT, fill=EMOTION))
p<- p + geom_bar(stat="identity")
p<- p + scale_fill_manual(values=c('#cc0000', '#009933','#9933ff','#ff00ff','#3366cc','#ffff66' ))
p<-p+ theme(axis.text.x = element_text(angle=45, hjust = 1, size=18), axis.title=element_text(size=14,face="bold"))
p<-p+ ggtitle("Emotion and Retweet by Candidate")
p<-p+ labs(x="Candidates", y="Number of Retweets")
p

# bar plot of sentiment and retweet count by subject matter
p<-ggplot(data=subset(DEBATE, DEBATE$CANDIDATE != 'No candidate mentioned'), aes(x=SUBJECT_MATTER, y=RETWEET_COUNT, fill=SENTIMENT))
p<- p + geom_bar(stat="identity")
p<- p + scale_fill_manual(values=c('#cc0000','#0099cc', '#009933'))
p<-p+ theme(axis.text.x = element_text(angle=45, hjust = 1, size=18), axis.title=element_text(size=14,face="bold"))
p<-p+ ggtitle("Sentiment and Retweet by Subject Matter")
p<-p+ labs(x="Subject", y="Number of Retweets")
p

# jitter plot of candidate by retweet count
g<-ggplot(subset(DEBATE), aes(x=SENTIMENT, y=SENTIMENT_CONFIDENCE))
g<-g+geom_jitter(alpha=0.8, aes(color=SENTIMENT),position = position_jitter(width = .05), size=1.5)
g

Contact GitHub API Training Shop Blog About 

� 2017 GitHub, Inc. Terms Privacy Security Status Help 


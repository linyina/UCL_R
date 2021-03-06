############################################################################################
#                               This is for STATxxxx ICA2                                  # 
#   This code is for analysing the EU referendum on 23rd June 2016
#   The data was from BBC's artical written by  by Martin Rosenbaum,  the BBC¡¯s Freedom of
#   Information specialist
#   Article at http://www.bbc.co.uk/news/uk-politics-38762034
#
############################################################################################

#####################################################
####    STEP 1: READING THE DATA AND RECODING    ####
#####################################################
Referendum <-read.csv("ReferendumResults.csv")
Referendum$Leave[Referendum$Leave==-1]<-NA


#### 
library(lattice); library(MASS); library(RColorBrewer); library(mgcv)
library(DAAG)#vif

#### Identify the actual proportion of leave votes
Referendum<- within(Referendum, LeaveProp<- Leave/NVotes)
####  i. Age
Referendum$Kids<- rowSums(Referendum[,11:16])   # Age 0-14
Referendum$Young<- rowSums(Referendum[,17:18])   # Age 15-24
Referendum$Work<- rowSums(Referendum[,18:29])  # Age 25-64
Referendum$Retire<- rowSums(Referendum[,23:26])  # Age 65 or more
Referendum$Age.clean<- cbind(Referendum[,c(52,53,54)])
####  ii. Ethnicity
Referendum$Eth.clean<- cbind(Referendum[,27:31])
####  iii. Accomodation status
Referendum$Accom.clean<- cbind(Referendum[,32:35])
####  iv. Education Level
Referendum$Edu.clean <- cbind(Referendum[,36:38])
names(Referendum$Edu.clean)<- c("No Quals", "GCSE Level", "Degree Level")
####  v. Occupation
Referendum$Occ.clean <- cbind(Referendum[,39:43])
####  vi. Deprivation
Referendum$Dep.clean <- cbind(Referendum[,45:46])
####  vii. Social Grades
Referendum$C1<- Referendum$C1C2DE-Referendum$C2DE
Referendum$C2<- Referendum$C2DE - Referendum$DE
Referendum$Soc.Clean <- cbind(Referendum[,c(61,62,49)])
head(Referendum$Soc.Clean)

####  vii. AreaType

tapply(Referendum$LeaveProp[1:803], INDEX=Referendum$RegionName[1:803], FUN=mean)
tapply(Referendum$LeaveProp[1:803], INDEX=Referendum$AreaType[1:803], FUN=mean)

#### We found that the mean and sd for London and Area:E09 is the same so we might
#### do a t-test:
var.test(Referendum$LeaveProp[Referendum$RegionName=="London"],
         Referendum$LeaveProp[Referendum$AreaType=="E09"])
###### p-value is 1: variance euqal
t.test(Referendum$LeaveProp[Referendum$RegionName=="London"],
       Referendum$LeaveProp[Referendum$AreaType=="E09"],
       var.equal=TRUE)
#### p-value is 1: Therefore we conclude that London and and E09 share the same data

Referendum$AreaType2[Referendum$AreaType=="E06"]<- 0
Referendum$AreaType2[Referendum$AreaType=="E07"]<- 1
Referendum$AreaType2[Referendum$AreaType=="E08"]<- 2
Referendum$AreaType2[Referendum$AreaType=="E09"]<- 2
Referendum$AreaType2<- factor(Referendum$AreaType2, levels=c(0,1,2), 
                              labels = c("Unitary", "Non-metro", "Cities"))
table(Referendum$AreaType2)

Ref.anal<- Referendum[1:803,]
attach(Ref.anal)

#######################################################################################
####                                                                               ####
#### STEP 2: EXPLORATORY ANALYSIS                                                  ####
####                                                                               ####
####   Aim: Reduce the number of candidate variables;                              ####
####        Identify any imprtant features of the data                             ####
####                                                                               ####
####   Instruction: (1) Define useful summary measures on contextual grounds       ####
####                    Age; Ethnicity; household deprivation etc.                 ####
####                (2) Define new variables based on the correlations between the ####
####                    existing variables. Highly correlated: PCA - WEEK10        ####
####                                                                               ####
#######################################################################################

####   (1) 
#### First: Some plotting settings and functions
if (!(names(dev.cur()) %in% c("windows","X11cairo"))) x11(width=8,height=6)

reg.colours <- brewer.pal(8,"Accent")

pic<-function(x){
  par(mfrow=c(2,2))
  hist(x)
  dotchart(x)
  boxplot(x)
  qqnorm(x);qqline(x, col="red")
  par(mfrow=c(1,1))
}
jpeg("LeaveProp.jpg",height = 480, width = 480)
pic(LeaveProp)
title("Proportion of Leave Votes", font.main=3, adj=1, col.main="red")
dev.off()
########### There's no theoretical proof that the covariates have 
########### linear correlation, therefore we use Spearman correlation.

#### i. Area
mean.reg<-tapply(LeaveProp, INDEX=RegionName, FUN=mean)
print(mean.reg)
mean.area<-tapply(LeaveProp, INDEX=AreaType, FUN=mean)
print(mean.area)
tapply(LeaveProp, INDEX=RegionName, FUN=sd)
tapply(LeaveProp, INDEX=AreaType, FUN=sd)
jpeg(filename = "boxp_region.jpg",width = 1000, height = 480)
par(mfrow=c(2,1))
boxplot(LeaveProp ~ RegionName, xlab="Region Name", ylab= "Proportion of Leave Votes", xaxt="n")
axis(1,at=c(1,2,3,4,5,6,7,8,9), labels=c("East Midlands", "East of England", "London", 
                               "North East", "North West","South East", "South West", "West Midlands",
                               "Yorkshire"))
points(mean.reg,col="red",pch=15)
boxplot(LeaveProp ~ AreaType, xlab= "Area Type", ylab= "Proportion of Leave Votes", xaxt="n") 
points(mean.area,col="red",pch=15)
axis(1,at=c(1,2,3,4), labels=c("Unitary Authorities", "Non-metropolitan", "Metropolitan", "London Boroughs"))
dev.off()
#### ii. Age
summary(Age.clean)
mean.age<- colMeans(Age.clean)
boxplot(Age.clean)
points(mean.age, col="red", pch=15)
#### Work occupies the largest proportion
cor(Age.clean, LeaveProp,  method = "spearman")
cor(MeanAge, LeaveProp,  method= "spearman")

#### Let's have a look at the correlation between mean age and leaveprop: 

####### a) contour plot
z<- kde2d(MeanAge, LeaveProp)
jpeg("countour_meanage.jpg", height = 480, width = 480)
contour(z, col="red", drawlabels = FALSE, main="Density estimation: contour plot"
        ,xlab = "Mean Age", ylab="Proportion of Leave Votes")
dev.off()
####### We see that as the mean age increase, the density of leaveprop become
####### larger.
####### b) xyplot
jpeg("xyplot_meanage.jpg", height = 480, width = 480)
xyplot(LeaveProp ~ MeanAge | RegionName, col=reg.colours[as.numeric(AreaType2)],
       xlab="Mean Age",ylab="Proportion of Leave Votes",
       main="Mean Age versus LeaveVotes Proportion for different regions")
dev.off()
cor( MeanAge[RegionName=="London"], LeaveProp[RegionName=="London"] )

xyplot(LeaveProp ~ MeanAge | AreaType2, col=reg.colours[as.numeric(AreaType2)],
       xlab="Mean Age",ylab="Proportion of Leave Votes",
       main="Mean Age versus LeaveVotes Proportion for different Area Type")


######## iii. Ethnicity
summary(Eth.clean)
mean.eth<- colMeans(Eth.clean)
boxplot(Eth.clean)
points(mean.eth, col="red", pch=15)
cor(LeaveProp, Eth.clean, method="spearman")

xyplot(LeaveProp ~ White | RegionName, 
       xlab="% of permanant residents: White",ylab="Proportion of Leave Votes", auto.key=list(columns=3,lines=TRUE,title="Region"),
       main="White versus Leave Proportion for different regions", col=reg.colours[as.numeric(AreaType2)])
xyplot(LeaveProp ~ Black | RegionName, 
       xlab="% of permanant residents: Black",ylab="Proportion of Leave Votes",
       main="Black versus Leave Proportion for different regions", col=reg.colours[as.numeric(AreaType2)])
xyplot(LeaveProp ~ Asian | RegionName, 
       xlab="% of permanant residents: Asian",ylab="Proportion of Leave Votes",
       main="Asian versus Leave Proportion for different regions", col=reg.colours[as.numeric(AreaType2)])



#### iv. Accomodation Status

summary(Accom.clean)
mean.accom<- colMeans(Accom.clean)
boxplot(Accom.clean)
points(mean.accom, col="red", pch=15)
cor(LeaveProp, Accom.clean, method = "spearman")
plot(LeaveProp ~ PrivateRent, col=reg.colours[as.numeric(RegionName)])
lines(lowess(PrivateRent, LeaveProp), col="red")
xyplot(LeaveProp ~ PrivateRent | RegionName, col=reg.colours[as.numeric(RegionName)],
       xlab="Poportion of Private Rent",ylab="Proportion of Leave Votes",
       main="% of PrivateRent versus LeaveVotes Proportion for different regions")

#### v. Education Level

summary(Referendum$Edu.clean)
mean.edu<- colMeans(Edu.clean)
boxplot(Referendum$Edu.clean)
points(mean.edu, col="red", pch=15)
cor(Edu.clean, LeaveProp, method = "spearman")

#### An exciting correlation between Education level and Leave Porportion
par(mfrow=c(3,1),mar=c(3,3,2,2))

plot(LeaveProp ~ NoQuals, xlab="% of Noquals People", col=reg.colours[as.numeric(RegionName)])
lines(lowess(NoQuals, LeaveProp), col="red")
mtext("Proportion of Leave Votes against Education Level", side=3)
plot(LeaveProp ~ L1Quals, xlab="% of GCSE LEVEL people", col=reg.colours[as.numeric(RegionName)])
lines(lowess(L1Quals, LeaveProp), col="red")
plot(LeaveProp ~ L4Quals_plus, xlab= "% of Degree + level people", col=reg.colours[as.numeric(RegionName)])
lines(lowess(L4Quals_plus, LeaveProp), col="red")



a3<- kde2d(NoQuals, LeaveProp)
contour(a3, col="green", main="Contour plot", 
        xlab="Proportion of NoQuals People", ylab="Proportion of Leave Votes")
a3<- kde2d(L1Quals, LeaveProp)
contour(a3, col="blue", main="Contour plot", 
        xlab="Proportion of GCSE Level People", ylab="Proportion of Leave Votes")
a4<- kde2d(L4Quals_plus, LeaveProp)
contour(a4, col="red", main="Contour plot", 
        xlab="Proportion of Degree Level People", ylab="Proportion of Leave Votes")
legend("topright", col=c("green","blue","red"),legend =c("NoQuals", "L1Quals", "L4Quals+") )

par(mfrow=c(1,1))
xyplot(LeaveProp ~ NoQuals | RegionName, col=reg.colours[as.numeric(AreaType2)],
       xlab="Proportion of Noquals People",ylab="Proportion of Leave Votes",
       main="% of permanent residents with no academic or professional
       qualifications versus LeaveVotes Proportion for different regions")
xyplot(LeaveProp ~ L1Quals | RegionName, col=reg.colours[as.numeric(AreaType2)],
       xlab="Proportion of GCSE Level People",ylab="Proportion of Leave Votes",
       main="% of permanent residents with only ¡®Level 1¡¯ qualifi-
       cations versus LeaveVotes Proportion for different regions")
xyplot(LeaveProp ~ L4Quals_plus | RegionName, col=reg.colours[as.numeric(AreaType2)],
       xlab="Proportion of Degree Level People",ylab="Proportion of Leave Votes",
       main="% of permanent residents educated to the equivalent of
       degree level or above versus LeaveVotes Proportion for different regions")

#### vi. Occupation
summary(Occ.clean)
mean.occ<- colMeans(Occ.clean)
boxplot(Occ.clean)
points(mean.occ, col="red", pch=15)
cor(LeaveProp, Occ.clean, method = "spearman")
plot(LeaveProp~ HigherOccup, col=reg.colours[as.numeric(RegionName)])
lines(lowess(HigherOccup, LeaveProp), col="red")
xyplot(LeaveProp ~ HigherOccup | RegionName, col=reg.colours[as.numeric(AreaType2)],
       xlab="Proportion of Higher Occupation People",ylab="Proportion of Leave Votes",
       main="% of permanent residents in ¡®higher-level¡¯ occupations versus LeaveVotes Proportion for different regions")
xyplot(LeaveProp ~ RoutineOccupOrLTU | RegionName, col=reg.colours[as.numeric(AreaType2)],
       xlab="Proportion of Routine or LTU People",ylab="Proportion of Leave Votes",
       main="% of permanent residents in ¡®routine¡¯ occupations or long-term non-employed for different regions")

#### vii. Deprivation
summary(Dep.clean)
mean.dep<- colMeans(Dep.clean)
boxplot(Dep.clean)
points(mean.dep, col="red", pch=15)
cor(LeaveProp,Dep.clean, method = "spearman")

xyplot(LeaveProp ~ Deprived | AreaType2, col=reg.colours[as.numeric(RegionName)],
       xlab="% of households that are ¡®deprived' in 1 dim",ylab="Proportion of Leave Votes",
       main="Deprivation versus LeaveVotes Proportion for different regions")
xyplot(LeaveProp ~ MultiDepriv | AreaType2, col=reg.colours[as.numeric(RegionName)],
       xlab="% of households that are ¡®deprived¡¯ in 2+ dim",ylab="Proportion of Leave Votes",
       main="Deprivation versus LeaveVotes Proportion for different regions")

#### viii. Social grades
summary(Referendum$Soc.Clean)
mean.soc<- colMeans(Soc.Clean)
boxplot(Referendum$Soc.Clean)
points(mean.soc, col="red", pch=15)
cor(LeaveProp, Soc.Clean, method = "spearman")

plot(LeaveProp~ C2,col=reg.colours[as.numeric(RegionName)])
lines(lowess(C2, LeaveProp), col="red")
xyplot(LeaveProp ~ C2 | RegionName, col=reg.colours[as.numeric(RegionName)],
       xlab="% of households in Skilled manual occupations",ylab="Proportion of Leave Votes",
       main="% of households in C2 for different regions")


####   (2) Colinearity

Cov.clean<- cbind(Referendum$Age.clean, Referendum$Edu.clean, Referendum$Eth.clean, 
                  Referendum$Occ.clean, Referendum$Soc.Clean)
round(cor(Cov.clean, method= "spearman"),2)


########### Function for PCA
Ref.pca<- function(x){
  pca.scale<- scale(x)
  test.pr <- prcomp(x)
  options(digits = 4)
  print(summary(test.pr, loadings=TRUE))
  print(test.pr)
  screeplot(test.pr, type="lines")
}

#### i. Age
round(cor(Age.clean, method = "spearman"),2)
pairs(Age.clean, col=reg.colours[as.numeric(RegionName)])
########### Young and Retire: negative correlation -0.67

####  ii. Ethnicity
round(cor(Eth.clean, method = "spearman"),2)
pairs(Eth.clean, col=reg.colours[as.numeric(RegionName)])
######### White has strong negative correlation with all the other!
######### Black and Asian: Strong positive correlation
######### Black and Indian; Indian and Asian; Pakistani and Asian
######### see the correlation of white and asian 
plot(White ~ Asian, xlab="Asian", ylab="White", col=reg.colours[as.numeric(RegionName)])
lines(lowess(Asian,White), col="red", lwd=2)

######### Strong negative linear correlation
round(cor(Referendum$Eth.clean, method= "spearman"),2)
Ref.pca(Referendum$Eth.clean)
#### The first two PCs has occupied 0.946, together with the scree plot which
#### shows the PC1 and PC2 illustrate enough information.
#Eth.F1 = 0.7766*White -0.1861*Black -0.5354*Asian -0.1811*Indian -0.2068*Pakistani
#Eth.F2 = -0.3089*White + 0.6908*Black -0.4864*Asian -0.1219*Indian -0.4188*Pakistani

Eth.pca<- prcomp(Referendum$Eth.clean)
Referendum$White.main<- Eth.pca$x[,1]
Referendum$Black.main<- Eth.pca$x[,2]
####  iii. Accommodation Type

round(cor(Accom.clean, method= "spearman"),2)
############ owned&OwnedOutright 0.89
############ Owned&Social Rent -0.81
############ Social Rent& Owned Outright
plot(Accom.clean, col=reg.colours[as.numeric(RegionName)])

plot(Owned ~ OwnedOutright, xlab= "% of households: Owned Outright", ylab="% of households: Owned", col=reg.colours[as.numeric(RegionName)])
lines(lowess( OwnedOutright,Owned), col="red", lwd=2)

Ref.pca(Referendum$Accom.clean)
#Accom.F1= 0.7643*Owned +0.3480*OwnedOutright-0.4646*SocialRent-0.2808*PrivateRent
#Accom.F2= -0.1112*Owned-0.0133*OwnedOutright-0.6482*SocialRent+0.7532*PrivateRent

Accom.pca<- prcomp(Referendum$Accom.clean)
Referendum$Owned.main<- Accom.pca$x[,1]
Referendum$PriRent.main<- Accom.pca$x[,2]



#### v. Education Level
round(cor(Edu.clean, method = "spearman"),2)
jpeg("Edu.jpg", height = 480, width = 480)
plot(Edu.clean,col=reg.colours[as.numeric(RegionName)])
dev.off()
plot(NoQuals ~ L4Quals_plus, xlab= "% of Degree Level +", ylab="% of No Quals", col=reg.colours[as.numeric(RegionName)])
lines(lowess( L4Quals_plus,NoQuals), col="red", lwd=2)

plot(L1Quals ~ L4Quals_plus, xlab= "% of Degree Level +", ylab="% of up to GCSE Level", col=reg.colours[as.numeric(RegionName)])
lines(lowess( L4Quals_plus,L1Quals), col="red", lwd=2)

Ref.pca(Referendum$Edu.clean)
# Edu.F1= 0.5188*NoQuals + 0.1888* L1Quals - 0.8333*L4Quals_plus
Edu.pca<- prcomp(Referendum$Edu.clean)
Referendum$Degree.less<- Edu.pca$x[,1]
Referendum$NoQuals.dom<- Edu.pca$x[,2]

# As the correlation between education and leaveprop is fairly high. Therefore we don't want to lose information
# for this covariate. As shown in pca analysis the first two PCA occupies 0.99

#### vi. Occupation
round(cor(Occ.clean,method="spearman"),2)  # Unemp & UnempRate_EA 0.99!!
plot(Occ.clean, col=reg.colours[as.numeric(RegionName)])
plot(Unemp ~ UnempRate_EA, xlab="% of economically active residents who are unemployed",
     ylab="% of permanent residents who are unemployed", col=reg.colours[as.numeric(RegionName)])
lines(lowess(UnempRate_EA,Unemp ), col="red", lwd=2)
#######STRONG LINEAR CORRELATION
Ref.pca(Referendum$Occ.clean)
#Occ.F1= 0.0124*Students-0.0829*Unemp-0.1404*UnempRate_EA+0.6538*HigherOccup-0.7381*RoutineOccupOrLTU
#Occ.F2= -0.9806*Students-0.0341*Unemp-0.0963*UnempRate_EA-0.1284*HigherOccup-0.1076*RoutineOccupOrLTU
Occ.pca<- prcomp(Referendum$Occ.clean)
Referendum$Higher.main<- Occ.pca$x[,1]
Referendum$Stu.less<- Occ.pca$x[,2]

#### vii. Deprivation
round(cor(Dep.clean, method="spearman"),2) #0.98! might drop one?
plot(Dep.clean,col=reg.colours[as.numeric(RegionName)])
lines(lowess(Dep.clean),col="red")
#### vii. Social grades
round(cor(Soc.Clean,method = "spearman"),2)
plot(Soc.Clean, col=reg.colours[as.numeric(RegionName)])
###### Not significant correlations



###########
Ref.anal<- Referendum[1:803,]
attach(Ref.anal)
Cov.clean2<- cbind(Age.clean, White.main, Black.main,Owned.main, PriRent.main, Degree.less, NoQuals.dom,
                   Higher.main, Stu.less, Dep.clean, Soc.Clean)
round(cor(Cov.clean2, method= "spearman"),2)   # Higher.main & DE -0.96 Higher.main& Degree.less -0.92
Cov.cor<-round(cor(Cov.clean2, method= "spearman"),2)
write.table(Cov.cor, file="Cov_cor.csv", col.names = TRUE, row.names = TRUE, sep = ",")


cor(LeaveProp, White.main,method="spearman")
cor(LeaveProp, Black.main, method="spearman") # Oops
cor(LeaveProp, Eth.clean, method="spearman")
cor(LeaveProp, Owned.main, method="spearman")
cor(LeaveProp, PriRent.main, method="spearman")
cor(LeaveProp, Accom.clean, method="spearman") # Seems ok? 
cor(LeaveProp, PriRent.main, method="spearman")
cor(LeaveProp, Degree.less, method="spearman")
cor(LeaveProp, NoQuals.dom, method = "spearman") # Oops
cor(LeaveProp, Higher.main, method="spearman")
cor(LeaveProp, Stu.less, method="spearman")

################################################################################
####                         STEP 3: STATISTICAL MODEL                      ####
####   Aim: Enable to predict the proportion of 'Leave' votes in a ward     ####
####   Instruction: Consider a range of models and use an appropriate suite ####
####               of diagnostics to assess them. And finally recommend a   ####
####               single model that is suitable for interpretation.        ####
################################################################################

#### Split the data into two chunks:
Ref.anal<- Referendum[1:803,]
Ref.na<- Referendum[804:1070,]
####################################################
#          Define some functions for cheking       #
# (1) Leverage

Lev <- function (model,x){
  hii<-hatvalues(model)
  p=x
  n=803
  Lev.log<- hii>2*(p+1)/n
  print(Lev.log[Lev.log==TRUE])
}


# (2) DFFITS

Dff<- function(model,x){
  dff<-dffits(model)
  p=x
  n=803
  Dff.log<- dff>2*sqrt((p+1)/n)
  print(Dff.log[Dff.log==TRUE])
}



#(3) Cook's distance

Cook<- function(model,x){
  cook<- cooks.distance(model)
  Cook.log<- cook> 8/(803-2*x)
  print(Cook.log[Cook.log==TRUE])
}

#(4) Vif

Ref.vif<-function(model){
  Vif<-vif(model, digits=3)
  print(Vif[Vif>=10])
}


Checking<- function(model,x){
  plot(model, which=1:4)
  cat("\n Levarage:\n")
  Lev(model,x)
  cat("\n DFFITS:\n")
  Dff(model,x)
  cat("\n Cook's distance:\n")
  Cook(model,x)
  cat("\n VIF \n")
  Ref.vif(model)
}


### Pearson Residual
Presid<- function(model){
  sum( resid(model,type="pearson")^2 ) / model$df.residual
}
#######################################################
#######################################################
#               Starting building models              #

## Plot settings:
par(mfrow=c(2,2),lwd=2,mar=c(3,3,2,2),mgp=c(2,0.75,0))

Ref.glm.full<- glm(formula = LeaveProp ~ RegionName + AreaType2 + Young + Work + Retire + 
                     White.main + Black.main + NoQuals + L1Quals + L4Quals_plus + Owned.main + 
                     PriRent.main + Higher.main + Stu.less + Deprived + MultiDepriv+  C1 + C2 + 
                     DE, family = binomial(link = "logit"), data = Ref.anal, weights = NVotes)
summary(Ref.glm.full)
Checking(Ref.glm.full,23)


##1) Start from Education!
Ref.glm.0<- glm(LeaveProp ~ NoQuals + L1Quals + L4Quals_plus, weights = NVotes, data = Ref.anal,
                family = binomial(link = "logit"))
summary(Ref.glm.0)
confint(Ref.glm.0)
drop1(Ref.glm.0)

# Compare with the model with PCA
Ref.glm.0a<- glm(LeaveProp ~ Degree.less + NoQuals.dom, weights = NVotes, data = Ref.anal,
                 family = binomial(link = "logit"))
summary(Ref.glm.0a)
confint(Ref.glm.0a)
drop1(Ref.glm.0a)

## Seems like we have higher AIC but lower standard error for each variable using PCA.
## We'll try PCA first and later we can change it to see what happens 
## if we use the originals

# Does order matters?
# Let's rearrange it...
Ref.glm.0b<- glm(LeaveProp ~ NoQuals + L4Quals_plus+ L1Quals , weights = NVotes, data = Ref.anal,
                 family = binomial(link = "logit"))
summary(Ref.glm.0b)  #No. Order does not matter!

#jpeg("model1.jpg", height = 480, width = 480)
#par(mfrow=c(2,2))
plot(Ref.glm.0a, main="First Model")
#dev.off()

## 2) Occupation
Ref.glm.1<- update(Ref.glm.0a, .~. + Higher.main + Stu.less)
summary(Ref.glm.1)
## AIC drops a lot
anova(Ref.glm.0a, Ref.glm.1, test = "Chi")

# Originals
Ref.glm.1a<- update(Ref.glm.0a, .~. + HigherOccup + Students + RoutineOccupOrLTU + Unemp + UnempRate_EA)
summary(Ref.glm.1a)

anova(Ref.glm.0a, Ref.glm.1a, Ref.glm.1)
AIC(Ref.glm.0a, Ref.glm.1a,Ref.glm.1)
## Well, the use of PCA here does not seems like a good choice.
## Therefore we continue our model building on 1a
drop1(Ref.glm.1a) # So far so good
Checking(Ref.glm.1a, 8) # Residual plots... horrible

## 3) Social Grades

Ref.glm.2<- update(Ref.glm.1a, .~. + C1 + C2 + DE)
summary(Ref.glm.2)  # HigherOccup!
anova(Ref.glm.1a, Ref.glm.2, test = "Chi")
AIC(Ref.glm.1a, Ref.glm.2)
drop1(Ref.glm.2)  # Omit HigherOccup will cause a drop of 2 in AIC 
# - not very large. will see it later
Checking(Ref.glm.2, 11) # VIF: HigherOccup!

# Let's first add more covariates first to see whether the situation will change

## 4) Age
Ref.glm.3<- update(Ref.glm.2, .~. + Young + Work + Retire)
summary(Ref.glm.3) # Unemp has relatively larger std.err but seems okay
# Oops now HigherOccup has a low p-value
# However.. Retire..

AIC(Ref.glm.2, Ref.glm.3) # did drop
anova(Ref.glm.2, Ref.glm.3, test = "Chi") # Not that much but did drop..
drop1(Ref.glm.3) # Retire ... for -1? but higher deviance
# What about the diagonostic plots?
Checking(Ref.glm.3,14) # Ummmm... does not look that good?
# VIF for HigherOccup... oops

# We don't see much deviance drop for adding age.

# 5) Ethnicity
# PCA
Ref.glm.4<- update(Ref.glm.3, .~. + White.main + Black.main)
summary(Ref.glm.4)    # White.main has p-value:0.90!

# Still let's try the model with original variables
Ref.glm.4a<- update(Ref.glm.3, .~. + White + Black + Asian + Indian + Pakistani)
summary(Ref.glm.4a)  # Embarrasing situation...
# Seems like the original variables fit the model better
# Retire and HigherOccup now seems good but work and Black..
# BUT!! From our previous experience! We won't drop them now!
anova(Ref.glm.3, Ref.glm.4, Ref.glm.4a, test = "Chi")
AIC(Ref.glm.3, Ref.glm.4, Ref.glm.4a) #4a
Checking(Ref.glm.4a, 19) # Ahhhhhh HigherOccup!!


# 6) Accommodation Type
Ref.glm.5<- update(Ref.glm.4a, .~. + Owned.main + PriRent.main)
summary(Ref.glm.5)
anova(Ref.glm.4a, Ref.glm.5, test = "Chi") # Only 114??

# See Originals!
Ref.glm.5a<- update(Ref.glm.4a, .~. + Owned + OwnedOutright + PrivateRent + SocialRent)
summary(Ref.glm.5a)
anova(Ref.glm.4a, Ref.glm.5, Ref.glm.5a)
# I would like to first conclude that accomodation have really tiny influence on our model.
# And.. again.. original variables fit better (why do we need PCA then)

# 7) Deprivation! Remember that we found them two has correlation value 0.98!
# Therefore we add it one at a time.
Ref.glm.6<- update(Ref.glm.5a, .~. + Deprived)
Ref.glm.6a<- update(Ref.glm.6, .~. + MultiDepriv)

anova(Ref.glm.5a, Ref.glm.6, Ref.glm.6a, test = "Chi")
# Ha! True that one covariate is not that necessary!

summary(Ref.glm.6a) # But there's still no evidence for dropping it??
# Black and work are still high (exciting for further testing)
drop1(Ref.glm.6a)
Presid(Ref.glm.6a)
# Before we move on.
# Let's see what happens if we change the education to the original variables.

Ref.glm.7<- update(Ref.glm.6a, .~. - Degree.less - NoQuals.dom + NoQuals + L1Quals + L4Quals_plus)
anova(Ref.glm.7, Ref.glm.6a, test="Chi")  # Ehh.. Still.. the originals?
summary(Ref.glm.7)

# 8) Now Factor covariates!

Ref.glm.8<- update(Ref.glm.7, .~. + RegionName)
summary(Ref.glm.8) # drop lots in AIC and deviance
# HigherOccup and Retire come again..
# Seems like we are having trouble with HigherOccup, Retire
# Work and Black
drop1(Ref.glm.8)  # From the list we can see that by far the most significant
# influence is by degree.less and region name which confirm
# our conclusion before
Checking(Ref.glm.8, 34)  # Residual plots are better!!

Ref.glm.9<-update(Ref.glm.8, .~. + AreaType2)
summary(Ref.glm.9)
AIC(Ref.glm.9, Ref.glm.8)
drop1(Ref.glm.9)  # Young and Retire still have the least influence

Checking(Ref.glm.9, 36)
Presid(Ref.glm.9)

#jpeg("model9.jpg", height = 480, width = 480)
#par(mfrow=c(2,2))
plot(Ref.glm.9, main="Model before interactions")
#dev.off()

# NOW INTERACTIONS

# We first do some cheating ^^
# Say if we find all the combination of interactions beween these covariates
# Let's see the most influencial ones and add them to our model

# In order to avoid you from running too long time for it (it takes few minutes)
# The code below I will treat it as comments with "#" at the beginning.
# And display the result as comments below.
# If you are interested in running for the result. Please remove the hash.
#
# Ref.full<- glm(LeaveProp ~ (HigherOccup + Students + RoutineOccupOrLTU + 
#                              Unemp + UnempRate_EA + C1 + C2 + DE + Young + Work + Retire + 
#                              White + Black + Asian + Indian + Pakistani + Owned + OwnedOutright + 
#                              PrivateRent + SocialRent + Deprived + MultiDepriv + NoQuals + 
#                              L1Quals + L4Quals_plus + RegionName + AreaType2)^2, family = binomial(link = "logit"), data = Ref.anal, weights = NVotes)

# summary(Ref.full)
# drop1(Ref.full)

# Checking(Ref.full, 581)
# Presid(Ref.full)
# Ref.full.2<- update(Ref.full, family=quasibinomial(link = "logit"))
# jpeg("Ref_full.jpg", width=480, height=480)
# par(mfrow=c(2,2))
# plot(Ref.full.2, main="Full model with all the cov and interactions")
# dev.off()

###################################################
#           Some significant Results              #
# DE:AreaType2                     2     4787 13107
# OwnedOutright:AreaType2          2     4758 13078
# RoutineOccupOrLTU:AreaType2      2     4744 13064
# Black:AreaType2                  2     4710 13031
# UnempRate_EA:AreaType2           2     4707 13028
# RegionName:AreaType2             2     4698 13015
# Students:AreaType2               2     4684 13005

# MultiDepriv:RegionName           6     4787 13100
# Retire:RegionName                6     4767 13080
# Work:RegionName                  6     4767 13080
# OwnedOutright:RegionName         6     4761 13074
# Deprived:RegionName              6     4746 13059
# DE:RegionName                    6     4738 13051
# RoutineOccupOrLTU:RegionName     6     4729 13042
# Owned:RegionName                 6     4717 13029
# Pakistani:RegionName             6     4707 13019
# PrivateRent:RegionName           6     4694 13007
# SocialRent:RegionName            6     4688 13001
# UnempRate_EA:RegionName          6     4680 12993


# OwnedOutright:L1Quals            1     4910 13233
# UnempRate_EA:OwnedOutright       1     4782 13105
# OwnedOutright:L4Quals_plus       1     4775 13098
# Unemp:OwnedOutright              1     4742 13065
# Retire:Deprived                  1     4737 13060
# Unemp:Retire                     1     4734 13056
# Unemp:UnempRate_EA               1     4722 13045
# UnempRate_EA:Retire              1     4715 13038
# Retire:MultiDepriv               1     4707 13030
# DE:Work                          1     4702 13025
# Retire:L1Quals                   1     4701 13023
# UnempRate_EA:L1Quals             1     4694 13017
# Unemp:L1Quals                    1     4694 13017
# Unemp:L4Quals_plus               1     4695 13017
# Unemp:Work                       1     4692 13015
# UnempRate_EA:L4Quals_plus        1     4687 13010
# Owned:L4Quals_plus               1     4680 13003
# White:L4Quals_plus               1     4673 12996
###################################################

# OwnedOutright:L1Quals 
Ref.glm.10<- update(Ref.glm.9,.~. + DE:AreaType2 + OwnedOutright:AreaType2 + RoutineOccupOrLTU:AreaType2
                    + MultiDepriv:RegionName + Retire:RegionName + Work:RegionName
                    + OwnedOutright:RegionName +Deprived:RegionName + DE:RegionName
                    + OwnedOutright:L1Quals +UnempRate_EA:OwnedOutright +OwnedOutright:L4Quals_plus
                    + Unemp:OwnedOutright + Retire:Deprived + Unemp:Retire)
summary(Ref.glm.10)  # HigherOccup and young and work
anova(Ref.glm.10, Ref.glm.9)
AIC(Ref.glm.10, Ref.glm.9)
drop1(Ref.glm.10)

Checking(Ref.glm.10, 77)

Ref.glm.10a<- update(Ref.glm.10, .~. - HigherOccup)
anova(Ref.glm.10a, Ref.glm.10, test = "Chi") #Don't reject
AIC(Ref.glm.10, Ref.glm.10a) # AIC -1
Checking(Ref.glm.10a, 95)

Presid(Ref.glm.10a)

Ref.glm.11<- update(Ref.glm.10a, family=quasibinomial(link = "logit"))
Checking(Ref.glm.11, 95)
summary(Ref.glm.11)
drop1(Ref.glm.11)
anova(Ref.glm.11, test="F")

# Work has P=0.932 but there is interaction beween work and regionname
Ref.fin<- update(Ref.glm.11, .~. - OwnedOutright:L4Quals_plus - Work:RegionName - Work)
predict(Ref.fin, newdata= Ref.na,se.fit = T, type="response")$residual.scale
summary(Ref.fin)
anova(Ref.fin, test = "F")

jpeg("final_model.jpg", height = 480, width = 480)
par(mfrow=c(2,2))
plot(Ref.fin,main = "Final Model")
dev.off()

# Check for residual pattern within groups and difference between groups      
jpeg("final_model_region.jpg", height=480, width=480)
xyplot(residuals(Ref.fin) ~ fitted(Ref.fin) | RegionName, 
       main = "glm.fin ¨C final model by plot",
       panel=function(x, y){ 
         panel.xyplot(x, y) 
         panel.loess(x, y, span = 0.75) 
         panel.lmline(x, y, lty = 2)  # Least squares broken line
       } 
)

dev.off()
###### Checking
pchisq(summary(Ref.fin)$dispersion * Ref.glm.10a$df.residual, Ref.glm.10a$df.residual, lower=F)

###############################################################################################################
#### 
####                                 STEP 4: PREDICTION
####    Instruction:(1) prediction error: pred.error = Act.p - pred.prob
####                (2) Act.prob ind. with pred.prob
####                (3) Variance(pred.error) = Var(Act.p) + Var(pred.prob)
####                (4) est.Var(Act.p)= pred.prob(1-pred.prob)/ni [ni is No. votes for the ith ward]
####                (5) est.std = sqrt(est.Var(act.p) + var(pred.prob))

Ref.pred<-predict(Ref.fin, newdata=Ref.na, type="response", se.fit = TRUE)
Final.output<- cbind(Ref.pred$fit, Ref.pred$se.fit)
write.table(Final.output, file="14006787_pred.dat", sep = " ", col.names = F)



######
score.glm<- function(model){
  Ref.pred<-predict(model, type="response", se.fit = TRUE)
  p<-Ref.pred$fit
  sigma<- sqrt((Ref.pred$se.fit^2 + summary(model)$dispersion * p * (1-p)/Ref.anal$NVotes))
  
  # Score
  s<- sum(log(sigma) + (LeaveProp - Ref.pred$fit)^2/ (2*sigma^2))
  print(s)
}

score.glm(Ref.fin)


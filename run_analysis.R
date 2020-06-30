library(dplyr)
library(data.table)

filename <- "Getting_Cleaning_Dataset.zip"
# Checking if archieve already exists.
if (!file.exists(filename)){
  fileURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
  download.file(fileURL, filename, method="curl")
}

# Checking if folder exists
if (!file.exists("UCI HAR Dataset")) { 
  unzip(filename) 
}

## Read .txt files into data frames
#
#features <- data.table::fread("UCI HAR Dataset/features.txt", col.names = c("n","functions"))
#features and activities labels
features <- data.table::fread("UCI HAR Dataset/features.txt", col.names = c("n","functions"))
activities <- data.table::fread("UCI HAR Dataset/activity_labels.txt", col.names = c("code", "activity"))

#Subjects group of 30 volunteers
subject_test <- data.table::fread("UCI HAR Dataset/test/subject_test.txt", col.names = "subject")
subject_train <- data.table::fread("UCI HAR Dataset/train/subject_train.txt", col.names = "subject")

#Activity (1 to 6) (WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING)
y_test <- data.table::fread("UCI HAR Dataset/test/y_test.txt", col.names = "code")
y_train <- data.table::fread("UCI HAR Dataset/train/y_train.txt", col.names = "code")

#Data where 70% of the volunteers was selected for generating the training data and 30% the test data
x_train <- data.table::fread("UCI HAR Dataset/train/X_train.txt", col.names = features$functions)
x_test <- data.table::fread("UCI HAR Dataset/test/X_test.txt", col.names = features$functions)

##Step 1: Merges the training and the test sets to create one data set.
#Combine test and train activities
X<-rbind(x_train,x_test)
Y<-rbind(y_train,y_test)
#combine subject 
Subject<-rbind(subject_train,subject_test)
#combine all data
All_data<-cbind(Subject,X,Y)
TidyData<-select(All_data,subject,code,contains("mean()"),contains("std()"))
## means Escaping so \\(\\) means match a literal "()" 
#TidyData<-select(All_data,matches("mean\\(\\)|std\\(\\)"))
#TidyData2<-grep("(mean|std).*",All_data,)
##Step 3: Uses descriptive activity names to name the activities in the data set.
#there are some ways to do that, the easy way is to use data.table library
#we use rows from Tidydata$code and then we assign the value of activity column from activities
TidyData$code<-activities[TidyData$code,activity]
#other alternative is use, we don't need to use data.table, package
#TidyData$code<-activities$activity[TidyData$code]
#we can also use factors to solve this:
#levels indicate the factors levels (optional), and with lable we changue the value of the levels
#TidyData$code<-factor(TidyData$code,levels = activities$code, labels = activities$activity)
##Step 4: Appropriately labels the data set with descriptive variable names.
#by names(TidyData)
#There are a few things to denote:
# "t" = time
# "f" = frequency
# "Acc" = Accelerometer
# "Mag" = Magnitude
# "Gyro" = Gyroscopic
# "Freq" = Frequency
# "stimed" = estimated
#ignore.case=TRUE means case insensitive
names(TidyData)[2] <- "activity"
#colnames(TidyData)[2]<-"activity"
names(TidyData)<-gsub("Acc", "Accelerometer", names(TidyData))
names(TidyData)<-gsub("Gyro", "Gyroscope", names(TidyData))
names(TidyData)<-gsub("BodyBody", "Body", names(TidyData))
names(TidyData)<-gsub("Mag", "Magnitude", names(TidyData))
names(TidyData)<-gsub("^t", "Time", names(TidyData))
names(TidyData)<-gsub("^f", "Frequency", names(TidyData))
names(TidyData)<-gsub("tBody", "TimeBody", names(TidyData))
names(TidyData)<-gsub("-mean()", "Mean", names(TidyData), ignore.case = TRUE)
names(TidyData)<-gsub("-std()", "STD", names(TidyData), ignore.case = TRUE)
names(TidyData)<-gsub("-freq()", "Frequency", names(TidyData), ignore.case = TRUE)
names(TidyData)<-gsub("angle", "Angle", names(TidyData))
names(TidyData)<-gsub("gravity", "Gravity", names(TidyData))


##Step 5: From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.
#we can use dplyr package and use summarise function, by adding across(everything())
#we can apply mean to all the columns, Also you can use sumarise_all that means the same
#tidyDataset <- TidyData %>% group_by(subject,activity) %>% 
#  summarise_all(funs(mean))
tidyDataset <- TidyData %>% group_by(subject,activity) %>% 
  summarise(across(everything(),mean))
write.table(tidyDataset, file = "tidyDataset.txt", row.names = FALSE)


#other alternative is using aggregate, we can specify the columns by=lis(columns)or 
#we can pass .~only the columns subject and activity
#Species~. means Species ~ Variable1 + Variable2
#https://stackoverflow.com/questions/6951090/what-does-the-period-mean-in-the-following-r-excerpt
#https://stackoverflow.com/questions/14087610/what-is-the-meaning-of-in-aggregate-function
#https://stackoverflow.com/questions/14078591/what-is-the-meaning-of-in-aggregate

tidyDataset2<-aggregate(. ~ subject + activity, TidyData, mean)
data.table::fwrite(x = tidyDataset2, file = "tidyData.csv", quote = FALSE)

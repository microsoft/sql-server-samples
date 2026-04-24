# Load the MicrosoftML library
library(MicrosoftML)

###
# Function to read in text file and perform data preparation
###
getData <- function(tempDir, dataFile) {

  # Unzip and read in the file
  data <- read.csv(unz(temp, dataFile),
                   sep = "\t")

  # Add column names. 1st column is the text, 2nd column is the rating
  colnames(data) <- c("Text", "Rating")

  # Convert to a string based dataframe
  data <- data.frame(lapply(data, as.character), stringsAsFactors=FALSE)

  # Convert the Rating column to numeric
  data$Rating <- as.integer(data$Rating)

  return(data)
}

# The data we'll use is the Sentiment Labelled Sentences Data Set
# http://archive.ics.uci.edu/ml/datasets/Sentiment+Labelled+Sentences#

# We'll pull the data from the UCI database directly
# Since it's a zip file, we'll need to store and extract from some local location

# So get a local temp location
temp <- tempfile()

# Download the zip file to the temp location
zipfile <- download.file("http://archive.ics.uci.edu/ml/machine-learning-databases/00331/sentiment%20labelled%20sentences.zip",temp)

# We'll use the imdb_labelled.txt file for training
dataTrain <- getData(temp, "sentiment labelled sentences/imdb_labelled.txt")

# Now let's setup the text featurizer transform
textTransform = list(featurizeText(vars = c(Features = "Text")))

# Train a linear model on featurized text
model <- rxFastLinear(
  Rating ~ Features,
  data = dataTrain,
  mlTransforms = textTransform
)

serialized <- rxSerializeModel(model, metadata = NULL, relatimeScoringOnly = FALSE)

saveRDS(serialized, file = "sentiment.rds")
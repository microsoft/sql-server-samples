
from azureml.core import Run

from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

from utils import *

# Fetch current run
run = Run.get_context()
    
# Fetch dataset from the run by name
dataset = run.input_datasets['training']

# Convert dataset to Pandas data frame
X_train, X_test, y_train, y_test = split_dataset(dataset)

# Setup scikit-learn pipeline
numeric_transformer = Pipeline(steps=[('scaler', StandardScaler())])
preprocessor = ColumnTransformer(transformers=[('num', numeric_transformer, list(X_train.columns.values))])

clf = Pipeline(steps=[('preprocessor', preprocessor),
                      ('classifier', LogisticRegression())])

model = clf.fit(X_train, y_train)

# Analyze model performance
analyze_model(clf, X_test, y_test)

# Save model
model_id = save_model(clf)

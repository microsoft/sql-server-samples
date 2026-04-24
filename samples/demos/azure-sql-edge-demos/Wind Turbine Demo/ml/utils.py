from skl2onnx.common.data_types import FloatTensorType, Int64TensorType, DoubleTensorType

import joblib
import pandas as pd

def download_model(run):
  run.download_file('model.joblib')
  model = joblib.load('model.joblib')
  return model

def convert_dataframe_schema(df, drop=None, batch_axis=False):
    inputs = []
    nrows = None if batch_axis else 1
    for k, v in zip(df.columns, df.dtypes):
        if drop is not None and k in drop:
            continue
        if v == 'int64':
            t = Int64TensorType([nrows, 1])
        elif v == 'float32':
            t = FloatTensorType([nrows, 1])
        elif v == 'float64':
            t = FloatTensorType([nrows, 1])
        else:
            raise Exception("Bad type")
        inputs.append((k, t))
    return inputs
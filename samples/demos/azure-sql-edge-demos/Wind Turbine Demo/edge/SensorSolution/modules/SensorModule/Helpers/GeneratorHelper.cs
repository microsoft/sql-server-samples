using System;
using System.Collections.Generic;
using System.Linq;

namespace SensorModule.Helpers
{
  public class GeneratorHelper
  {
    private Random _random = new Random();

    public double GetGearBoxOilLevel()
    {
      int trendSign = _random.Next(-1, 1);
      var offset = GetRandomNumber(0, 5);
      offset = trendSign < 0 ? offset * -1 : offset;
      return 40 + offset;
    }

    public double GetGearBoxTemp()
    {
      var offset = GetRandomNumber(0, 3);
      int trendSign = _random.Next(-2, 1);
      var toReturn = 53.0 + offset;

      if (toReturn > 40)
      {
        offset = trendSign < 0 ? offset * -1 : offset;
      }
      else if (toReturn > 61)
      {
        offset *= -1;
      }

      toReturn += offset;

      return toReturn > 61 ? GetRandomNumber(60, 61) : toReturn;
    }

    public double GetGeneratorActivePower(double windSpeed)
    {
      Dictionary<int, double> Values = new Dictionary<int, double>()
      {
        { 0, -1.165047329 },
        { 1, -1.561275004 },
        { 2, -1.523817212 },
        { 3, 0.258328264 },
        { 4, 39.48032308 },
        { 5, 129.0223307 },
        { 6, 296.3115464 },
        { 7, 533.6013549 },
        { 8, 784.2038201 },
        { 9, 1033.222044 },
        { 10, 1282.494906 },
        { 11, 1522.07693 },
        { 12, 1710.51213 },
        { 13, 1847.754821 },
        { 14, 1909.292275 },
        { 15, 1929.077495 },
      };

      var ws = Convert.ToInt32(Math.Round(windSpeed));
      ws = ws > 15 ? 15 : ws;
      var apAvg = Values[ws];
      int trendSign = _random.Next(-2, 1);

      double offset;
      if (ws <= 3)
      {
        offset = GetRandomNumber(-0.04, 0.01);
      }
      else if (ws <= 7)
      {
        offset = GetRandomNumber(0.01, 0.15);
      }
      else if (ws <= 12)
      {
        offset = GetRandomNumber(0.01, 0.63);
      }
      else
      {
        offset = GetRandomNumber(0.01, 0.94);
      }

      offset = trendSign < 0 ? offset * -1 : offset;
      var toReturn = (apAvg * offset) + apAvg;
      return toReturn > 2100 ? 2100 : toReturn;
    }

    public double GetGeneratorSpeed(double windSpeed)
    {
      Dictionary<int, double> Values = new Dictionary<int, double>()
      {
        { 0, 29.5339 },
        { 1, 93.4983 },
        { 2, 123.626 },
        { 3, 270.0063 },
        { 4, 850.3199 },
        { 5, 1059.4094 },
        { 6, 1317.4786 },
        { 7, 1548.3753 },
        { 8, 1635.4728 },
        { 9, 1660.1312 },
        { 10, 1685.2159 },
        { 11, 1709.3631 },
        { 12, 1722.729 },
        { 13, 1743.2982 },
        { 14, 1739.6748 },
        { 15, 1737.1417 }
      };

      var ws = Convert.ToInt32(Math.Round(windSpeed));
      ws = ws > 15 ? 15 : ws;
      var gsAvg = Values[ws];
      double rate;
      int trendSign = _random.Next(-3, 1);

      if (ws <= 5)
      {
        rate = GetRandomNumber(0, 0.7);
      }
      else if (ws <= 8)
      {
        rate = GetRandomNumber(0.001, 0.055);
      }
      else if (ws <= 12)
      {
        rate = GetRandomNumber(0.001, 0.04362);
        trendSign = _random.Next(-1, 2);
      }
      else
      {
        rate = GetRandomNumber(0.001, 0.374);
        trendSign = _random.Next(-1, 3);
      }
      rate = trendSign < 0 ? rate * -1 : rate;
      var toReturn = (gsAvg * rate) + gsAvg;
      return toReturn > 1800.100 + 5 ? 1800.100 : toReturn;
    }

    public double GetGeneratorStatorTemp(double generatorSpeed)
    {
      double[] avgTempValues = { 15.0, 45.5, 55.3, 72.5 };
      var gs = Convert.ToInt32(Math.Round(generatorSpeed));
      var offset = GetRandomNumber(0, 10);
      int trendSign = _random.Next(-2, 2);
      offset = trendSign < 0 ? offset * -1 : offset;
      double toReturn;
      if (gs < 450)
      {
        toReturn = avgTempValues[0] + offset;
      }
      else if (gs < 900)
      {
        toReturn = avgTempValues[1] + offset;
      }
      else if (gs < 1350)
      {
        toReturn = avgTempValues[2] + offset;
      }
      else
      {
        offset = GetRandomNumber(0, 5);
        toReturn = avgTempValues[3] + offset;
      }

      return toReturn > 83 ? GetRandomNumber(82, 84) : toReturn;
    }

    public double GetGeneratorTorque(double generatorSpeed, double activePower)
    {
      var toReturn = activePower == 0 || generatorSpeed == 0 ? 0 : (activePower / generatorSpeed) * (30 / 3.1416);
      return toReturn > 10 ? GetRandomNumber(9, 10) : toReturn;
    }

    public double GetGridFrequency(double activePower)
    {
      if (activePower == 0)
      {
        return 0;
      }
      else
      {
        var offset = GetRandomNumber(0, 0.5);
        int trendSign = _random.Next(-1, 1);
        offset = trendSign < 0 ? offset * -1 : offset;

        return 50 + offset;
      }
    }

    public double GetVoltage(double activePower)
    {
      var offset = GetRandomNumber(0, 20);
      int trendSign = _random.Next(-1, 4);
      offset = trendSign < 0 ? GetRandomNumber(0, 5) * -1 : offset;
      return activePower != 0 ? 690 + offset : 0;
    }

    public double GetHydraulicOilPressure()
    {
      var offset = GetRandomNumber(0, 10);
      int trendSign = _random.Next(-2, 1);
      double toReturn = 250 + offset;

      if (toReturn > 249)
      {
        offset = trendSign < 0 ? offset * -1 : offset;
      }
      else if (toReturn > 375)
      {
        offset *= -1;
      }

      toReturn += offset;

      return toReturn > 380 ? GetRandomNumber(379, 380) : toReturn;
    }

    public double GetNacelleAngle(double windDirection)
    {
      var offset = GetRandomNumber(0, 10);
      int trendSign = _random.Next(-2, 2);
      offset = trendSign < 0 ? offset * -1 : offset;
      var toReturn = windDirection + offset;
      return toReturn > 360 ? GetRandomNumber(358, 360) : toReturn;
    }

    public double GetPitchAngle(double windSpeed)
    {
      Dictionary<int, PitchAngleReference> Values = new Dictionary<int, PitchAngleReference>()
      {
        { 0, new PitchAngleReference { Ratio = 0.98, Avg = 54.24524239 } },
        { 1, new PitchAngleReference {Ratio = 1.014, Avg = 51.67482604 } },
        { 2, new PitchAngleReference {Ratio = 1.4, Avg = 50.15667612  } },
        { 3, new PitchAngleReference {Ratio = 3.75, Avg = 44.47110192  } },
        { 4, new PitchAngleReference {Ratio = 10.9, Avg = 10.16831867  } },
        { 5, new PitchAngleReference {Ratio = 8, Avg = 3.753638458  } },
        { 6, new PitchAngleReference {Ratio = 8.6, Avg = 3.143487107  } },
        { 7, new PitchAngleReference {Ratio = 8.1, Avg = 3.851029642  } },
        { 8, new PitchAngleReference {Ratio = 7, Avg = 5.51622539  } },
        { 9, new PitchAngleReference {Ratio = 12.3, Avg = 5.607653521  } },
        { 10, new PitchAngleReference {Ratio = 11.3, Avg = 4.906807873  } },
        { 11, new PitchAngleReference {Ratio = 12.5, Avg = 4.556013361  } },
        { 12, new PitchAngleReference {Ratio = 7.6, Avg = 5.461135239  } },
        { 13, new PitchAngleReference {Ratio = 4, Avg = 6.617167409  } },
        { 14, new PitchAngleReference {Ratio = 6.5, Avg = 9.174521933  } },
        { 15, new PitchAngleReference {Ratio = 7.1, Avg = 11.5855706  } },
      };

      var ws = Convert.ToInt32(Math.Round(windSpeed));
      ws = ws > 15 ? 15 : ws;
      var paAvg = Values[ws].Avg;
      var rate = GetRandomNumber(0.001, Values[ws].Ratio);

      int trendSign = _random.Next(-2, 2);

      rate = trendSign < 0 ? rate * -1 : rate;
      var toReturn = (paAvg * rate) + paAvg;

      // This is needed as the avg for speeds greater than 5 are to low and the min value is to close to 0.
      if (ws >= 5 && toReturn < 0)
      {
        toReturn = GetRandomNumber(-13, 1);
      }

      return toReturn > 262.6 + 5 ? 262.6 : toReturn;
    }

    public double GetVibration(double windSpeed)
    {
      if (windSpeed < 5)
      {
        return GetRandomNumber(0, 50);
      }
      else
      {
        return windSpeed * 13;
      }
    }

    public double GetRandomNumber(double minimum, double maximum)
    {
      return _random.NextDouble() * (maximum - minimum) + minimum;
    }

    public bool GetRandomBool(int truePercentage = 50)
    {
      return _random.NextDouble() < truePercentage / 100.0;
    }

    public double CalculateStandardDeviation(IEnumerable<double> values)
    {
      double standardDeviation = 0;

      if (values.Any())
      {
        // Compute the average.     
        double avg = values.Average();

        // Perform the Sum of (value-avg)_2_2.      
        double sum = values.Sum(d => Math.Pow(d - avg, 2));

        // Put it all together.      
        standardDeviation = Math.Sqrt((sum) / (values.Count() - 1));
      }

      return double.IsNaN(standardDeviation) ? 0 : standardDeviation;
    }
  }

  class PitchAngleReference
  {
    public double Ratio { get; set; }
    public double Avg { get; set; }
  }
}

using SensorModule.Models;
using SensorModule.Services.Interfaces;
using Parquet;
using Parquet.Data;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace SensorModule.Services
{
  public class DataExporterService : IDataExporterService
  {
    public void SaveParquet(IEnumerable<TrainingWindTurbineRecord> records, string outputFile)
    {
      //create data columns with schema metadata and the data you need
      var turbineId = new DataColumn(
         new DataField<int>("TurbineId"),
         records.Select(x => x.TurbineId).ToArray());

      var gearboxOilLevel = new DataColumn(
         new DataField<double>("GearboxOilLevel"),
         records.Select(x => x.GearboxOilLevel).ToArray());

      var gearboxOilTemp = new DataColumn(
         new DataField<double>("GearboxOilTemp"),
         records.Select(x => x.GearboxOilTemp).ToArray());

      var generatorActivePower = new DataColumn(
         new DataField<double>("GeneratorActivePower"),
         records.Select(x => x.GeneratorActivePower).ToArray());

      var generatorSpeed = new DataColumn(
         new DataField<double>("GeneratorSpeed"),
         records.Select(x => x.GeneratorSpeed).ToArray());

      var generatorTemp = new DataColumn(
         new DataField<double>("GeneratorTemp"),
         records.Select(x => x.GeneratorTemp).ToArray());

      var generatorTorque = new DataColumn(
         new DataField<double>("GeneratorTorque"),
         records.Select(x => x.GeneratorTorque).ToArray());

      var gridFrequency = new DataColumn(
         new DataField<double>("GridFrequency"),
         records.Select(x => x.GridFrequency).ToArray());

      var gridVoltage = new DataColumn(
         new DataField<double>("GridVoltage"),
         records.Select(x => x.GridVoltage).ToArray());

      var hydraulicOilPressure = new DataColumn(
         new DataField<double>("HydraulicOilPressure"),
         records.Select(x => x.HydraulicOilPressure).ToArray());

      var nacelleAngle = new DataColumn(
         new DataField<double>("NacelleAngle"),
         records.Select(x => x.NacelleAngle).ToArray());

      var overallWindDirection = new DataColumn(
         new DataField<double>("OverallWindDirection"),
         records.Select(x => x.OverallWindDirection).ToArray());

      var overalWindSpeedStdDev = new DataColumn(
         new DataField<double>("WindSpeedStdDev"),
         records.Select(x => x.WindSpeedStdDev).ToArray());

      var precipitation = new DataColumn(
         new DataField<bool>("Precipitation"),
         records.Select(x => x.Precipitation).ToArray());

      var turbineWindDirection = new DataColumn(
         new DataField<double>("TurbineWindDirection"),
         records.Select(x => x.TurbineWindDirection).ToArray());

      var turbineSpeedStdDev = new DataColumn(
         new DataField<double>("TurbineSpeedStdDev"),
         records.Select(x => x.TurbineSpeedStdDev).ToArray());

      var windSpeedAverage = new DataColumn(
         new DataField<double>("WindSpeedAverage"),
         records.Select(x => x.WindSpeedAverage).ToArray());

      var windTempAverage = new DataColumn(
         new DataField<double>("WindTempAverage"),
         records.Select(x => x.WindTempAverage).ToArray());

      var alterBlades = new DataColumn(
         new DataField<bool>("AlterBlades"),
         records.Select(x => x.AlterBlades).ToArray());

      var pitchAngle = new DataColumn(
         new DataField<double>("PitchAngle"),
         records.Select(x => x.PitchAngle).ToArray());

      var vibration = new DataColumn(
         new DataField<double>("Vibration"),
         records.Select(x => x.Vibration).ToArray());

      var turbineSpeedAverage = new DataColumn(
         new DataField<double>("TurbineSpeedAverage"),
         records.Select(x => x.TurbineSpeedAverage).ToArray());

      // create file schema
      var schema = new Schema(turbineId.Field, gearboxOilLevel.Field, gearboxOilTemp.Field, generatorActivePower.Field, generatorSpeed.Field, generatorTemp.Field, generatorTorque.Field, gridFrequency.Field, gridVoltage.Field, hydraulicOilPressure.Field,
        nacelleAngle.Field, overallWindDirection.Field, overalWindSpeedStdDev.Field, precipitation.Field, turbineWindDirection.Field, turbineSpeedStdDev.Field, windSpeedAverage.Field, windTempAverage.Field, pitchAngle.Field, vibration.Field, turbineSpeedAverage.Field, alterBlades.Field);

      var outputPath = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);

      using (Stream fileStream = File.OpenWrite(Path.Combine(outputPath, $"{outputFile}.parquet")))
      {
        using (var parquetWriter = new ParquetWriter(schema, fileStream))
        {
          // create a new row group in the file
          using (ParquetRowGroupWriter groupWriter = parquetWriter.CreateRowGroup())
          {
            groupWriter.WriteColumn(turbineId);
            groupWriter.WriteColumn(gearboxOilLevel);
            groupWriter.WriteColumn(gearboxOilTemp);
            groupWriter.WriteColumn(generatorActivePower);
            groupWriter.WriteColumn(generatorSpeed);
            groupWriter.WriteColumn(generatorTemp);
            groupWriter.WriteColumn(generatorTorque);
            groupWriter.WriteColumn(gridFrequency);
            groupWriter.WriteColumn(gridVoltage);
            groupWriter.WriteColumn(hydraulicOilPressure);
            groupWriter.WriteColumn(nacelleAngle);
            groupWriter.WriteColumn(overallWindDirection);
            groupWriter.WriteColumn(overalWindSpeedStdDev);
            groupWriter.WriteColumn(precipitation);
            groupWriter.WriteColumn(turbineWindDirection);
            groupWriter.WriteColumn(turbineSpeedStdDev);
            groupWriter.WriteColumn(windSpeedAverage);
            groupWriter.WriteColumn(windTempAverage);
            groupWriter.WriteColumn(pitchAngle);
            groupWriter.WriteColumn(vibration);
            groupWriter.WriteColumn(turbineSpeedAverage);
            groupWriter.WriteColumn(alterBlades);
          }
        }
      }
    }
  }
}

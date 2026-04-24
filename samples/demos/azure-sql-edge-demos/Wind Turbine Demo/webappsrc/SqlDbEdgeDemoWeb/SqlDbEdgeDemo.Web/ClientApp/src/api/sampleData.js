export const getForecasts = async () => {
  const forecastsResponse = await fetch("api/SampleData/WeatherForecasts");
  return await forecastsResponse.json();
};

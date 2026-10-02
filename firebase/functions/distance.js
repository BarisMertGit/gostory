function distanceKm(a, b) {
  const rad = x => x * Math.PI / 180;
  const dlat = rad(b.latitude - a.latitude);
  const dlng = rad(b.longitude - a.longitude);
  const h = Math.sin(dlat / 2) ** 2 + Math.cos(rad(a.latitude)) * Math.cos(rad(b.latitude)) * Math.sin(dlng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(Math.max(0, 1 - h)));
}
module.exports = {distanceKm};

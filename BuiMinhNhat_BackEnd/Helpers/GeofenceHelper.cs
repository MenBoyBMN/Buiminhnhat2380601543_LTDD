namespace BuiMinhNhat_BackEnd.Helpers
{
    public static class GeofenceHelper
    {
        private const double EarthRadiusMeters = 6371000.0;

        /// <summary>
        /// Tính khoảng cách giữa hai tọa độ GPS (Latitude, Longitude) theo công thức Haversine (đơn vị: mét)
        /// </summary>
        public static double CalculateDistanceMeters(double lat1, double lon1, double lat2, double lon2)
        {
            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);

            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

            return Math.Round(EarthRadiusMeters * c, 2);
        }

        private static double ToRadians(double degrees)
        {
            return degrees * Math.PI / 180.0;
        }
    }
}

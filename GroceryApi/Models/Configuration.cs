namespace GroceryApi.Configuration
{
    
    public enum MatchType
    {
        MatchAll,
        MatchMajor,
        MatchBoth
    }
    public class MatchSettings
    {
        public MatchType MatchType { get; set; }
        public double MatchPercentCutoff { get; set; }
        public double MatchMajorPercentCutoff { get; set; }
    }
}
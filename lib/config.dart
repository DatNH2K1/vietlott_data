/// Configuration constants for the application.
class AppConfig {
  /// The GitHub username/organization where the repository is hosted.
  static const String githubUsername = 'DatNH2K1';

  /// The name of the GitHub repository.
  static const String githubRepo = 'vietlott_data';

  /// The branch name to fetch raw data from (e.g. 'main' or 'master').
  static const String githubBranch = 'main';

  /// Base raw URL for fetching files from the GitHub repository.
  static const String rawGithubBaseUrl =
      'https://raw.githubusercontent.com/$githubUsername/$githubRepo/$githubBranch';

  /// Returns the raw GitHub URL for a specific product's JSONL data file.
  ///
  /// Example:
  /// `getProductDataUrl('power535')` returns:
  /// `https://raw.githubusercontent.com/DatNH2K1/vietlott_data/main/data/power535.jsonl`
  static String getProductDataUrl(String productName) {
    return '$rawGithubBaseUrl/data/$productName.jsonl';
  }
}

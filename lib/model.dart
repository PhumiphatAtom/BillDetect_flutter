import 'dart:convert';

Result resultFromJson(String str) => Result.fromJson(json.decode(str));

String resultToJson(Result data) => json.encode(data.toJson());

class Result {
  Result({
    this.detect,
    this.link,
  });

  String detect;
  String link;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    detect: json["Detect"],
    link: json["Link"],
  );

  Map<String, dynamic> toJson() => {
    "Detect": detect,
    "Link": link,
  };
}
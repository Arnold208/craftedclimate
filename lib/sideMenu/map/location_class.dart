import 'dart:convert';

List<DeviceLocation> deviceLocationFromJson(String str) => List<DeviceLocation>.from(json.decode(str).map((x) => DeviceLocation.fromJson(x)));

String deviceLocationToJson(List<DeviceLocation> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DeviceLocation {
    String auid;
    Locationn location;
    Status status;
    int battery;

    DeviceLocation({
        required this.auid,
        required this.location,
        required this.status,
        required this.battery,
    });

    factory DeviceLocation.fromJson(Map<String, dynamic> json) => DeviceLocation(
        auid: json["auid"],
        location: Locationn.fromJson(jsonDecode(json["location"])),
        status: statusValues.map[json["status"]]!,
        battery: json["battery"],
    );

    Map<String, dynamic> toJson() => {
        "auid": auid,
        "location": jsonEncode(location.toJson()),
        "status": statusValues.reverse[status],
        "battery": battery,
    };
}

class Locationn {
    String country;
    String region;
    String city;
    String street;
    String municipality;
    String municipalitySubdivision;
    double latitude;
    double longitude;

    Locationn({
        required this.country,
        required this.region,
        required this.city,
        required this.street,
        required this.municipality,
        required this.municipalitySubdivision,
        required this.latitude,
        required this.longitude,
    });

    factory Locationn.fromJson(Map<String, dynamic> json) => Locationn(
        country: json["country"],
        region: json["region"],
        city: json["city"],
        street: json["street"],
        municipality: json["municipality"],
        municipalitySubdivision: json["municipalitySubdivision"],
        latitude: json["latitude"].toDouble(),
        longitude: json["longitude"].toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "country": country,
        "region": region,
        "city": city,
        "street": street,
        "municipality": municipality,
        "municipalitySubdivision": municipalitySubdivision,
        "latitude": latitude,
        "longitude": longitude,
    };
}

enum Status {
    OFFLINE,
    ONLINE
}

final statusValues = EnumValues({
    "offline": Status.OFFLINE,
    "online": Status.ONLINE
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
        reverseMap = map.map((k, v) => MapEntry(v, k));
        return reverseMap;
    }
}

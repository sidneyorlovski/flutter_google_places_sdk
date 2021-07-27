import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

const title = 'Flutter Google Places SDK Example';

// note: do NOT store your api key in here or in the code at all.
// use an external source such as file or firebase remote config
const API_KEY = 'my-key';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final FlutterGooglePlacesSdk _places;

  //
  String? _predictLastText;

  bool _predicting = false;
  dynamic _predictErr;

  List<AutocompletePrediction>? _predictions;

  //
  final TextEditingController _fetchPlaceIdController = TextEditingController();
  List<PlaceField> _placeFields = [
    PlaceField.Address,
    PlaceField.AddressComponents,
    PlaceField.BusinessStatus,
    PlaceField.Id,
    PlaceField.Location,
    PlaceField.Name,
    PlaceField.OpeningHours,
    PlaceField.PhoneNumber,
    PlaceField.PhotoMetadatas,
    PlaceField.PlusCode,
    PlaceField.PriceLevel,
    PlaceField.Rating,
    PlaceField.Types,
    PlaceField.UserRatingsTotal,
    PlaceField.UTCOffset,
    PlaceField.Viewport,
    PlaceField.WebsiteUri,
  ];

  bool _fetching = false;
  dynamic _fetchingErr;

  Place? _place;

  @override
  void initState() {
    super.initState();

    _places = FlutterGooglePlacesSdk(API_KEY);
  }

  @override
  Widget build(BuildContext context) {
    final predictionsWidgets = _buildPredictionWidgets();
    final fetchPlaceWidgets = _buildFetchPlaceWidgets();
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: Padding(
        padding: EdgeInsets.all(30),
        child: ListView(
            children: predictionsWidgets +
                [
                  SizedBox(height: 16),
                ] +
                fetchPlaceWidgets),
      ),
    );
  }

  void _onPredictTextChanged(String value) {
    _predictLastText = value;
  }

  void _fetch() async {
    if (_fetching) {
      return;
    }

    final text = _fetchPlaceIdController.text;
    final hasContent = text.isNotEmpty;

    setState(() {
      _fetching = hasContent;
      _fetchingErr = null;
    });

    if (!hasContent) {
      return;
    }

    try {
      final result = await _places.fetchPlace(_fetchPlaceIdController.text,
          fields: _placeFields);

      setState(() {
        _place = result.place;
        _fetching = false;
      });
    } catch (err) {
      setState(() {
        _fetchingErr = err;
        _fetching = false;
      });
    }
  }

  void _predict() async {
    if (_predicting) {
      return;
    }

    final hasContent = _predictLastText?.isNotEmpty ?? false;

    setState(() {
      _predicting = hasContent;
      _predictErr = null;
    });

    if (!hasContent) {
      return;
    }

    try {
      final result = await _places.findAutocompletePredictions(
        _predictLastText!,
        countries: ['il'],
        newSessionToken: false,
        origin: LatLng(lat: 43.12, lng: 95.20),
      );

      setState(() {
        _predictions = result.predictions;
        _predicting = false;
      });
    } catch (err) {
      setState(() {
        _predictErr = err;
        _predicting = false;
      });
    }
  }

  void _onItemClicked(AutocompletePrediction item) {
    _fetchPlaceIdController.text = item.placeId;
  }

  Widget _buildPredictionItem(AutocompletePrediction item) {
    return InkWell(
      onTap: () => _onItemClicked(item),
      child: Column(children: [
        Text(item.fullText),
        Text(item.primaryText + ' - ' + item.secondaryText),
        const Divider(thickness: 2),
      ]),
    );
  }

  Widget _buildErrorWidget(dynamic err) {
    final theme = Theme.of(context);
    final errorText = err == null ? '' : err.toString();
    return Text(errorText,
        style: theme.textTheme.caption?.copyWith(color: theme.errorColor));
  }

  List<Widget> _buildFetchPlaceWidgets() {
    return [
      // --
      TextFormField(controller: _fetchPlaceIdController),
      ElevatedButton(
        onPressed: _fetching == true ? null : _fetch,
        child: const Text('Fetch Place'),
      ),

      // -- Error widget + Result
      _buildErrorWidget(_fetchingErr),
      Text('Result: ' + (_place?.toString() ?? 'N/A')),
    ];
  }

  List<Widget> _buildPredictionWidgets() {
    return [
      // --
      TextFormField(
        onChanged: _onPredictTextChanged,
      ),
      ElevatedButton(
        onPressed: _predicting == true ? null : _predict,
        child: const Text('Predict'),
      ),

      // -- Error widget + Result
      _buildErrorWidget(_predictErr),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: (_predictions ?? [])
            .map(_buildPredictionItem)
            .toList(growable: false),
      ),
      Image(
        image: FlutterGooglePlacesSdk.ASSET_POWERED_BY_GOOGLE_ON_WHITE,
      ),
    ];
  }
}
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:project_flutter/hover_image.dart';
// import 'package:project_flutter/image_card.dart';
import 'package:project_flutter/image_generator.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 110, 60, 196)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var history = <WordPair>[];
  var favorites = <WordPair>[];
  var images = <GeneratedImage>[];

  void getNext() {
    String apiKey = dotenv.env['OPEN_AI_KEY'] ?? 'DefaultAPIKey';
    print('API Key: $apiKey');
    history.insert(0, current);
    current = WordPair.random();

    print('current: $current, history: $history');
    notifyListeners();
  }

  void removeFavorite(WordPair word) {
    favorites.remove(word);
    notifyListeners();
  }

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void addImage(GeneratedImage image) {
    images.add(image);
    notifyListeners();
  }

  void removeImage(GeneratedImage image) {
    images.remove(image);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();

      case 1:
        page = FavoritesPage();
      case 2:
        page = GalleryPage();

      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.primaryContainer,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 900),
        child: page,
      ),
    );
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLargeScreen = constraints.maxWidth > 800;
          return Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: isLargeScreen,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.image),
                      label: Text('Gallery'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: mainArea,
              ),
            ],
          );
        },
      ),
    );
  }
}

class GeneratedImage {
  final String image;
  final String text;

  GeneratedImage(this.image, this.text);
}

class GalleryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var images = appState.images;
    var theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: AnimatedTextKit(
            animatedTexts: [
              TyperAnimatedText(
                'Gallery',
                speed: Duration(milliseconds: 100),
                textStyle: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary),
              ),
            ],
            totalRepeatCount: 1,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int numberCol = constraints.maxWidth > 800 ? 3 : 2;
                return GridView.count(crossAxisCount: numberCol, children: [
                  for (var image in images)
                    Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              // child: ClipRRect(
                              //   borderRadius: BorderRadius.circular(10),
                              //   child: Image.network(
                              //     image.image,
                              //     fit: BoxFit.cover,
                              //   ),
                              // ),

                              child: HoverDeleteImage(
                                imageUrl: image.image,
                                onDelete: () {
                                  appState.removeImage(image);
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(image.text,
                                style: TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                ]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    final List<int> colorCodes = <int>[600, 400, 200];
    var favorites = appState.favorites;

    if (favorites.isEmpty) {
      return Center(child: Text('No favorites yet :/'));
    }
    return Column(children: [
      Padding(
          padding: const EdgeInsets.only(top: 20),
          child: AnimatedTextKit(
            animatedTexts: [
              TyperAnimatedText(
                'Favorites',
                speed: Duration(milliseconds: 100),
                textStyle: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary),
              ),
            ],
            totalRepeatCount: 1,
          )),
      Expanded(
        child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: favorites.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color:
                      Colors.deepPurple[colorCodes[index % colorCodes.length]],
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 50,
                width: 100,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text('${favorites[index]}',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 20,
                            )),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () {
                            appState.removeFavorite(favorites[index]);
                          },
                          icon: Icon(
                            Icons.delete,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ]),
              );
            }),
      ),
    ]);
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  String? imageUrl;
  bool isLoading = false;

  void updateImage(MyAppState appState) {
    setState(() {
      GeneratedImage? foundImage = appState.images.lastWhere(
        (img) => img.text == appState.current.asLowerCase,
        orElse: () => GeneratedImage("", ""),
      );

      imageUrl = foundImage.image.isNotEmpty ? foundImage.image : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    updateImage(appState);
    final ImageGenerator imageGenerator = ImageGeneratorFactory.create();

    var theme = Theme.of(context);

    void generateImage() async {
      setState(() {
        isLoading = true;
      });
      String? url =
          await imageGenerator.generate(appState.current.asPascalCase);

      if (url != null) {
        appState.addImage(GeneratedImage(url, appState.current.asLowerCase));
        updateImage(appState);
      }
      setState(() {
        isLoading = false;
      });
    }

    void _addItem(WordPair word) {
      if (appState.history.length >= 8) {
        _listKey.currentState!.removeItem(
          appState.history.length - 1,
          (context, animation) => FadeTransition(
            opacity: animation,
          ),
        );
        appState.history.removeAt(appState.history.length - 1);
      }
      appState.getNext();

      if (_listKey.currentState != null) {
        _listKey.currentState!.insertItem(0);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 200,
              height: 400,
              child: AnimatedList(
                reverse: true,
                initialItemCount: appState.history.length,
                itemBuilder: (context, index, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (appState.favorites.any((element) =>
                              element.asLowerCase ==
                              appState.history[index].asLowerCase))
                            Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(
                                  Icons.favorite,
                                  size: 15,
                                  color: theme.colorScheme.primary,
                                )),
                          Text(
                            appState.history[index].asLowerCase,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                key: _listKey,
                controller: _scrollController,
              ),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          RandomWord(pair: pair),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 30,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Favorite'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  _addItem(appState.current);
                },
                child: Text('Next'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        generateImage();
                      },
                child: Text('Generate Image'),
              ),
            ],
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(80),
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(),
              ),
            ),
          if (imageUrl != null && !isLoading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: Duration(seconds: 1),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: SizedBox(
                  key: ValueKey(imageUrl),
                  width: 200,
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class RandomWord extends StatelessWidget {
  const RandomWord({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      elevation: 3,
      color: theme.colorScheme.onPrimaryFixedVariant,
      child: AnimatedSize(
        alignment: Alignment.topCenter,
        duration: Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: pair.first,
                  style: style.copyWith(fontStyle: FontStyle.italic)),
              TextSpan(
                  text: pair.second,
                  style: style.copyWith(fontWeight: FontWeight.bold)),
            ]),
            semanticsLabel: pair.asPascalCase,
          ),
        ),
      ),
    );
  }
}

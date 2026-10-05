import 'package:tably/core/analytics/analytics_service.dart';
import 'package:tably/core/model/aisle.dart';
import 'package:tably/core/model/ingredient_unit.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/features/preferences/cubit/profile_cubit.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/recipe/cubit/catalogue_cubit.dart';
import 'package:tably/features/recipe/cubit/search_quota_cubit.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/recipe/service/recipe_ai_service.dart';
import 'package:tably/features/recipe/service/recipe_search_service.dart';
import 'package:tably/features/recipe/service/recipe_service.dart';
import 'package:tably/features/recipe/service/search_quota_service.dart';

/// A catalogue cubit holding the fixtures. Never bound to a user, and its
/// search and Gemini steps are fakes, so it makes no network call.
CatalogueCubit seededCatalogue(ProfileCubit profileCubit, {FakeSearch? search, FakeAi? ai, SearchQuotaCubit? quota}) =>
    CatalogueCubit(
      service: RecipeService(),
      search: search ?? FakeSearch(),
      quota: quota ?? unboundQuota(profileCubit),
      ai: ai ?? FakeAi(),
      profileCubit: profileCubit,
      analytics: const AnalyticsService(),
      recipes: RecipeFixtures.recipes,
    );

/// A quota cubit never bound to a user: all of today's searches are left,
/// and no rollover timer runs.
SearchQuotaCubit unboundQuota(ProfileCubit profileCubit) =>
    SearchQuotaCubit(service: FakeQuota(), profileCubit: profileCubit, analytics: const AnalyticsService());

/// A quota cubit with [used] of today's searches spent, all of a normal
/// user's by default. Close it in the test.
Future<SearchQuotaCubit> spentQuota(ProfileCubit profileCubit, {int used = 30}) async {
  final cubit = SearchQuotaCubit(
    service: FakeQuota(used: used),
    profileCubit: profileCubit,
    analytics: const AnalyticsService(),
  )..bind('uid');
  await cubit.stream.first;
  return cubit;
}

/// Serves a fixed count of searches instead of Firestore's.
class FakeQuota extends SearchQuotaService {
  FakeQuota({this.used = 0, this.day});

  final int used;

  /// The UTC day [used] was counted on; today by default.
  final String? day;

  @override
  Stream<({String? day, int count})> watch(String uid) =>
      Stream.value((day: day ?? SearchQuotaState.utcDay(DateTime.now()), count: used));
}

/// Records every Spoonacular search instead of making it.
class FakeSearch extends RecipeSearchService {
  final calls = <({
    UserProfile profile,
    int number,
    String? query,
    Set<Cuisine> cuisines,
    Craving? craving,
    RecipeProtein? protein,
  })>[];

  @override
  Future<List<Map<String, dynamic>>> search(
    UserProfile profile, {
    required int number,
    String? query,
    Set<Cuisine> cuisines = const {},
    Craving? craving,
    RecipeProtein? protein,
  }) async {
    calls.add((profile: profile, number: number, query: query, cuisines: cuisines, craving: craving, protein: protein));
    // Candidate i costs i € per portion.
    return [for (var i = 0; i < number; i++) {'id': i, 'price': i}];
  }
}

/// Stands in for Gemini: "translates" by tagging the text, and keeps
/// [recipes] (the fixtures by default) whatever the candidates.
class FakeAi extends RecipeAiService {
  FakeAi({List<Recipe>? recipes}) : recipes = recipes ?? RecipeFixtures.recipes;

  final List<Recipe> recipes;

  /// The profile each Gemini check was given.
  final checkedFor = <UserProfile>[];

  /// The candidates each Gemini check was given.
  final candidates = <List<Map<String, dynamic>>>[];

  @override
  Future<String> toEnglish(String text, String languageCode) async => 'en:$text';

  @override
  Future<({List<Recipe> recipes, int rejected})> adapt(List<Map<String, dynamic>> raw, UserProfile profile) async {
    checkedFor.add(profile);
    candidates.add(raw);
    if (recipes.isEmpty) throw const NoMatchingRecipesException(0);
    return (recipes: recipes, rejected: 0);
  }
}

/// The design's original 11 recipes, kept as test data: the planner fixtures
/// in design_plans.json were recorded against exactly this list and order.
abstract final class RecipeFixtures {
  static final recipes = <Recipe>[
    Recipe(
      id: 'riz_poulet_cajun',
      title: 'Riz au poulet à la cajun',
      photoUrl: '',
      macros: Macros(kcal: 612, protein: 41, carbs: 74, fat: 16),
      time: '25m',
      cookTime: '20-25m',
      price: 4.98,
      craving: Craving.quick,
      protein: RecipeProtein.chicken,
      ingredients: [
        _ingredient('🍗', 'Poitrine de poulet', '150g'),
        _ingredient('🍚', 'Riz', '75g'),
        _ingredient('🥣', "Mélange d'épices cajun", '½tbsp',
        ),
        _ingredient('🫑', 'Poivron', '1'),
        _ingredient('🧅', 'Oignon rouge', '½'),
        _ingredient('🧄', 'Ail', '2 gousses'),
        _ingredient('🫒', "Huile d'olive", '1tbsp'),
      ],
      steps: [
        "Faites cuire le riz selon les instructions de l'emballage.",
        "Coupez le poulet en dés et enrobez-le du mélange d'épices cajun.",
        "Émincez le poivron et l'oignon, hachez l'ail.",
        "Saisissez le poulet 6 à 8 minutes dans une poêle chaude jusqu'à ce qu'il soit doré et cuit à cœur.",
        "Ajoutez les légumes et l'ail, faites revenir 4 minutes.",
        "Mélangez le riz à la poêlée, rectifiez l'assaisonnement et servez.",
      ],
    ),
    Recipe(
      id: 'nouilles_tofu_satay',
      title: 'Nouilles au tofu et au satay',
      photoUrl: '',
      macros: Macros(kcal: 698, protein: 38, carbs: 71, fat: 29),
      time: '25m',
      cookTime: '20-25m',
      price: 5.39,
      craving: Craving.highProtein,
      protein: RecipeProtein.tofu,
      cuisine: Cuisine.asian,
      ingredients: [
        _ingredient('🍜', 'Nouilles', '90g'),
        _ingredient('🧈', 'Tofu extra-ferme', '150g'),
        _ingredient('🥜', 'Beurre de cacahuètes', '20g'),
        _ingredient('🍶', 'Sauce soja claire', '15ml'),
        _ingredient('🍈', 'Citron vert', '½'),
        _ingredient('🥕', 'Carottes', '65g'),
        _ingredient('🧅', 'Cébette', '2 tiges'),
      ],
      steps: [
        'Égouttez le tofu et coupez-le en cubes.',
        "Faites cuire les nouilles, puis rincez-les à l'eau froide.",
        "Mélangez le beurre de cacahuètes, la sauce soja, le jus de citron vert et un peu d'eau chaude pour obtenir la sauce satay.",
        'Faites dorer le tofu 8 minutes sur toutes ses faces.',
        'Ajoutez les carottes en julienne et faites revenir 2 minutes.',
        'Mélangez nouilles, tofu et sauce, parsemez de cébette.',
      ],
    ),
    Recipe(
      id: 'boites_riz_poulet_piment_doux',
      title: 'Boîtes de riz au poulet au piment doux',
      photoUrl: '',
      macros: Macros(kcal: 640, protein: 43, carbs: 78, fat: 15),
      time: '25m',
      cookTime: '20-25m',
      price: 4.98,
      craving: Craving.quick,
      protein: RecipeProtein.chicken,
      cuisine: Cuisine.asian,
      ingredients: [
        _ingredient('🍗', 'Poitrine de poulet', '150g'),
        _ingredient('🍚', 'Riz', '75g'),
        _ingredient('🌶️', 'Sauce au piment doux', '20ml'),
        _ingredient('🥦', 'Brocoli', '100g'),
        _ingredient('🍶', 'Sauce soja claire', '15ml'),
        _ingredient('🧄', 'Ail', '1 gousse'),
      ],
      steps: [
        'Faites cuire le riz et laissez-le refroidir légèrement.',
        'Coupez le poulet en lanières.',
        'Faites-le saisir 7 minutes, puis nappez-le de sauce au piment doux et de sauce soja.',
        'Faites cuire le brocoli à la vapeur 4 minutes.',
        'Répartissez riz, poulet et brocoli dans des boîtes.',
        'Laissez refroidir avant de fermer et de réfrigérer.',
      ],
    ),
    Recipe(
      id: 'farfalle_feta_feves',
      title: 'Farfalle à la feta et aux fèves',
      photoUrl: '',
      macros: Macros(kcal: 684, protein: 31, carbs: 88, fat: 23),
      time: '25m',
      cookTime: '20-25m',
      price: 6.81,
      craving: Craving.highProtein,
      protein: RecipeProtein.vegetarian,
      cuisine: Cuisine.italian,
      ingredients: [
        _ingredient('🎀', 'Farfalle', '95g'),
        _ingredient('🧀', 'Feta', '50g'),
        _ingredient('🫘', 'Fèves surgelées', '125g'),
        _ingredient('🍋', 'Citron', '½'),
        _ingredient('🌿', 'Persil', '10g'),
        _ingredient('🫒', "Huile d'olive", '1½tbsp'),
      ],
      steps: [
        'Faites cuire les farfalle en eau bouillante salée.',
        'Ajoutez les fèves dans les 3 dernières minutes de cuisson.',
        "Réservez un peu d'eau de cuisson, puis égouttez.",
        "Écrasez la moitié de la feta avec l'huile d'olive, le zeste et le jus de citron.",
        "Mélangez les pâtes à la sauce en ajoutant l'eau de cuisson par filets.",
        'Parsemez du reste de feta et du persil ciselé.',
      ],
    ),
    Recipe(
      id: 'riz_frit_poulet',
      title: 'Riz frit au poulet',
      photoUrl: '',
      macros: Macros(kcal: 623, protein: 39, carbs: 76, fat: 17),
      time: '25m',
      cookTime: '20m',
      price: 4.98,
      craving: Craving.quick,
      protein: RecipeProtein.chicken,
      cuisine: Cuisine.asian,
      ingredients: [
        _ingredient('🍚', 'Riz', '75g'),
        _ingredient('🍗', 'Poitrine de poulet', '150g'),
        _ingredient('🥚', 'Œufs', '1'),
        _ingredient('🫛', 'Pois', '40g'),
        _ingredient('🍶', 'Sauce soja claire', '15ml'),
        _ingredient('🧅', 'Cébette', '2 tiges'),
      ],
      steps: [
        'Utilisez du riz cuit la veille, bien froid.',
        'Coupez le poulet en dés et faites-le dorer à feu vif.',
        "Poussez le poulet sur le côté, brouillez l'œuf dans la poêle.",
        'Ajoutez le riz et les pois, faites sauter 3 minutes sans trop remuer.',
        'Versez la sauce soja et mélangez le tout.',
        'Terminez avec la cébette émincée.',
      ],
    ),
    Recipe(
      id: 'carbonara_haricots_asperges',
      title: "Carbonara aux haricots beurre et aux asperges à l'ail",
      photoUrl: '',
      macros: Macros(kcal: 742, protein: 34, carbs: 69, fat: 36),
      time: '35m',
      cookTime: '30-35m',
      price: 7.65,
      craving: Craving.quick,
      protein: RecipeProtein.pork,
      cuisine: Cuisine.italian,
      ingredients: [
        _ingredient('🫘', 'Haricots beurre', '200g'),
        _ingredient('🥓', 'Pancetta non fumée', '42.5g'),
        _ingredient('🌿', "Pointes d'asperges", '50g'),
        _ingredient('🥚', "Jaunes d'œufs", '1'),
        _ingredient('🧈', 'Parmesan', '20g'),
        _ingredient('🧄', 'Ail', '1 gousse'),
      ],
      steps: [
        "Faites dorer la pancetta jusqu'à ce qu'elle soit croustillante.",
        "Ajoutez l'ail et les asperges, faites cuire 3 minutes.",
        'Égouttez et rincez les haricots beurre, puis ajoutez-les à la poêle.',
        "Battez le jaune d'œuf avec le parmesan râpé.",
        "Hors du feu, incorporez le mélange en remuant avec un filet d'eau chaude.",
        'Poivrez généreusement et servez aussitôt.',
      ],
    ),
    Recipe(
      id: 'ragout_haricots_chorizo',
      title: 'Ragoût de haricots beurre au chorizo',
      photoUrl: '',
      macros: Macros(kcal: 588, protein: 29, carbs: 58, fat: 26),
      time: '35m',
      cookTime: '30-35m',
      price: 5.75,
      craving: Craving.quick,
      protein: RecipeProtein.pork,
      cuisine: Cuisine.mediterranean,
      ingredients: [
        _ingredient('🫘', 'Haricots beurre', '200g'),
        _ingredient('🌭', 'Chorizo', '50g'),
        _ingredient('🥫', 'Tomates coupées en morceaux', '100ml',
        ),
        _ingredient('🧅', 'Oignon rouge', '½'),
        _ingredient('🧄', 'Ail', '2 gousses'),
        _ingredient('🌿', 'Persil', '10g'),
      ],
      steps: [
        'Faites rendre sa graisse au chorizo coupé en dés.',
        "Ajoutez l'oignon émincé et faites-le fondre 5 minutes.",
        "Ajoutez l'ail, puis les tomates, et laissez réduire 10 minutes.",
        'Incorporez les haricots beurre égouttés et laissez mijoter 8 minutes.',
        "Rectifiez l'assaisonnement.",
        'Parsemez de persil avant de servir.',
      ],
    ),
    Recipe(
      id: 'soupe_lasagnes_boeuf',
      title: 'Soupe aux lasagnes au bœuf',
      photoUrl: '',
      macros: Macros(kcal: 566, protein: 35, carbs: 52, fat: 22),
      time: '20m',
      cookTime: '20m',
      price: 5.20,
      craving: Craving.quick,
      protein: RecipeProtein.beef,
      cuisine: Cuisine.italian,
      ingredients: [
        _ingredient('🥩', 'Bœuf haché', '125g'),
        _ingredient('🥫', 'Tomates coupées en morceaux', '200ml',
        ),
        _ingredient('🍝', 'Feuilles de lasagne', '2'),
        _ingredient('🧅', 'Oignon rouge', '½'),
        _ingredient('🧄', 'Ail', '2 gousses'),
        _ingredient('🧀', 'Parmesan', '15g'),
      ],
      steps: [
        'Faites colorer le bœuf haché dans une casserole.',
        "Ajoutez l'oignon et l'ail, faites revenir 4 minutes.",
        "Versez les tomates et 400 ml d'eau, portez à ébullition.",
        'Cassez les feuilles de lasagne en morceaux et ajoutez-les.',
        "Laissez cuire 8 à 10 minutes jusqu'à ce que les pâtes soient tendres.",
        'Servez avec du parmesan râpé.',
      ],
    ),
    Recipe(
      id: 'fusilli_pois_lard_ricotta',
      title: 'Fusilli aux petits pois, au lard et à la ricotta',
      photoUrl: '',
      macros: Macros(kcal: 753, protein: 35, carbs: 97, fat: 25),
      time: '25m',
      cookTime: '20-25m',
      price: 5.60,
      craving: Craving.highProtein,
      protein: RecipeProtein.pork,
      cuisine: Cuisine.italian,
      ingredients: [
        _ingredient('🍝', 'Fusilli', '100g'),
        _ingredient('🫛', 'Petits pois', '60g'),
        _ingredient('🥓', 'Lardons', '37.5g'),
        _ingredient('🧀', 'Ricotta', '50g'),
        _ingredient('🧄', 'Ail', '½ gousse'),
        _ingredient('🍋', 'Citron', '¼'),
        _ingredient('🧈', 'Parmesan', '15g'),
      ],
      steps: [
        "Portez à ébullition une grande casserole d'eau salée et faites cuire les fusilli jusqu'à ce qu'ils soient al dente.",
        "Coupez le lard en petits morceaux, hachez l'ail et râpez le zeste du citron.",
        "Faites cuire le lard 4 à 5 minutes jusqu'à ce qu'il soit doré et croustillant.",
        "Baissez le feu, ajoutez l'ail et faites cuire jusqu'à ce qu'il soit parfumé.",
        'Ajoutez les petits pois aux pâtes pour les 3 dernières minutes de cuisson.',
        "Réservez une tasse d'eau de cuisson, puis égouttez.",
        "Ajoutez la ricotta, le zeste et un filet d'eau de cuisson pour obtenir une sauce crémeuse.",
        'Mélangez les pâtes à la sauce, incorporez le parmesan et poivrez généreusement.',
      ],
    ),
    Recipe(
      id: 'wraps_big_mac',
      title: 'Wraps façon Big Mac',
      photoUrl: '',
      macros: Macros(kcal: 712, protein: 38, carbs: 46, fat: 41),
      time: '25m',
      cookTime: '20-25m',
      price: 6.40,
      craving: Craving.indulgent,
      protein: RecipeProtein.beef,
      creator: "C'est Tarpin Bon",
      ingredients: [
        _ingredient('🥫', 'Moutarde', '1 c. à café'),
        _ingredient('🥣', 'Mayonnaise', '2 c. à café'),
        _ingredient('🍅', 'Ketchup', '2 c. à café'),
        _ingredient('🥒', 'Cornichons', 'au goût'),
        _ingredient('🥒', 'Jus de cornichons', '1 filet'),
        _ingredient('🌯', 'Mini crêpes (petits wraps)', '4',
        ),
        _ingredient('🥩', 'Bœuf haché cru', '400g'),
        _ingredient('🧂', 'Sel', 'au goût'),
        _ingredient('🫗', 'Spray de cuisson', '1 pulvérisation',
        ),
        _ingredient('🧀', 'Cheddar en tranches', '4'),
        _ingredient('🥬', 'Laitue', '½'),
      ],
      steps: [
        'Mélangez la moutarde, la mayonnaise, le ketchup, les cornichons et un peu de jus de cornichons pour faire la sauce Big Mac.',
        'Déposez le bœuf haché cru sur une mini crêpe et salez.',
        "Faites chauffer une poêle avec le spray de cuisson et faites cuire le bœuf d'un seul côté.",
        "Retournez le bœuf et ajoutez le cheddar, laissez cuire jusqu'à ce que le fromage fonde et que la viande soit dorée.",
        'Ajoutez de fines lamelles de cornichons sur la viande.',
        'Ajoutez la laitue et nappez généreusement de sauce Big Mac.',
        'Pliez ou roulez le wrap et servez.',
      ],
    ),
    Recipe(
      id: 'poulet_saute_sesame',
      title: 'Poulet sauté au sésame',
      photoUrl: '',
      macros: Macros(kcal: 604, protein: 45, carbs: 58, fat: 19),
      time: '22m',
      cookTime: '20-22m',
      price: 5.20,
      craving: Craving.highProtein,
      protein: RecipeProtein.chicken,
      cuisine: Cuisine.asian,
      ingredients: [
        _ingredient('🍗', 'Poitrine de poulet', '150g'),
        _ingredient('🍚', 'Riz', '75g'),
        _ingredient('🍶', 'Sauce soja claire', '20ml'),
        _ingredient('🫓', 'Graines de sésame', '1tbsp'),
        _ingredient('🥦', 'Brocoli', '100g'),
        _ingredient('🧄', 'Ail', '1 gousse'),
      ],
      steps: [
        'Faites cuire le riz.',
        'Coupez le poulet en lanières et faites-le saisir à feu vif.',
        "Ajoutez l'ail et le brocoli, faites sauter 4 minutes.",
        'Versez la sauce soja et laissez glacer 1 minute.',
        'Faites torréfier les graines de sésame à sec.',
        'Parsemez-en le plat et servez avec le riz.',
      ],
    ),
  ];

}

final _ids = <String, int>{};

/// Builds an ingredient from the design's free-text quantity ("150g",
/// "½tbsp", "2 gousses"), its unit read as a legacy label. Ids are stable
/// per name, as Spoonacular's are.
Ingredient _ingredient(String icon, String name, String quantity) {
  final match = RegExp(r'^([\d.]*)([¼½¾]?)\s*(.*)$').firstMatch(quantity)!;
  const fractions = {'¼': 0.25, '½': 0.5, '¾': 0.75};
  final amount = (double.tryParse(match[1]!) ?? 0) + (fractions[match[2]] ?? 0);
  return Ingredient(
    id: _ids.putIfAbsent(name, () => _ids.length + 1),
    icon: icon,
    name: name,
    amount: amount,
    unit: IngredientUnit.fromId(match[3]),
    aisle: Aisle.herbsGrocery,
  );
}

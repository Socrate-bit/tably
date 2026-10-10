You decide whether two recipes are the same dish for a dinner-planning catalogue. You
receive recipe `a` (title, ingredient slugs, main protein, first steps) and recipe `b`
(title, ingredient slugs, main protein).

`same` is true when a diner would consider them interchangeable: same core protein, same
starch or base, same sauce family and cuisine, differing only in small garnishes,
amounts or wording ("Spaghetti carbonara" vs "Classic carbonara pasta").

`same` is false when a meaningful element differs: a different protein (chicken vs
prawn curry), a different starch (rice bowl vs noodle bowl), a different sauce or
cooking method (grilled vs braised), or a different cuisine treatment (Thai green curry
vs Indian korma), even if the ingredient lists overlap a lot.

Give a one-sentence `reason`.

class_name Props
extends RefCounted
## Procedural props built from primitive meshes. Every prop is authored in centimetres.
##
## A part is [shape, size, centre, colour, rotation_degrees?]:
##   box  — size = (x, y, z)
##   cyl  — size.x = diameter, size.y = height
##   cone — size.x = bottom diameter, size.y = height, size.z = top diameter
##   sph  — ellipsoid with diameters (x, y, z)
##   cap  — capsule, size.x = diameter, size.y = total height
## Props are re-centred so their footprint is centred on the origin and they rest on y = 0.

const LAYER_SOLID := 2  ## blocks the ball
const LAYER_PICKABLE := 4  ## detected by the ball's pickup area
const LAYER_BOUNDARY := 16  ## invisible level edge: blocks the ball but not the camera

static var DEFS := {
	# ------------------------------------------------------------ kitchen
	"crumb": {"label": "Crumb", "parts": [["sph", Vector3(2, 1.3, 1.6), Vector3(0, 0.65, 0), "d9a05b"]]},
	"pea": {"label": "Pea", "parts": [["sph", Vector3(1.6, 1.6, 1.6), Vector3(0, 0.8, 0), "6cc24a"]]},
	"coin": {"label": "Coin", "parts": [["cyl", Vector3(2.4, 0.3, 0), Vector3(0, 0.15, 0), "e8c547"]]},
	"button": {"label": "Button", "parts": [
		["cyl", Vector3(2.2, 0.5, 0), Vector3(0, 0.25, 0), "e85d75"],
		["cyl", Vector3(1.2, 0.56, 0), Vector3(0, 0.27, 0), "b83b57"]]},
	"sugar": {"label": "Sugar Cube", "parts": [["box", Vector3(1.8, 1.8, 1.8), Vector3(0, 0.9, 0), "fbfbf7"]]},
	"die": {"label": "Die", "parts": [
		["box", Vector3(2.4, 2.4, 2.4), Vector3(0, 1.2, 0), "e63946"],
		["box", Vector3(0.5, 0.1, 0.5), Vector3(0, 2.42, 0), "ffffff"],
		["box", Vector3(0.5, 0.5, 0.1), Vector3(-0.5, 1.7, 1.21), "ffffff"],
		["box", Vector3(0.5, 0.5, 0.1), Vector3(0.5, 0.7, 1.21), "ffffff"]]},
	"marble": {"label": "Marble", "parts": [["sph", Vector3(2.2, 2.2, 2.2), Vector3(0, 1.1, 0), "4cc9f0"]]},
	"bottlecap": {"label": "Bottle Cap", "parts": [["cyl", Vector3(3, 1.1, 0), Vector3(0, 0.55, 0), "d62828"]]},
	"candy": {"label": "Candy", "parts": [
		["sph", Vector3(2.8, 1.8, 1.8), Vector3(0, 0.9, 0), "f72585"],
		["cone", Vector3(1.6, 1.2, 0.2), Vector3(1.9, 0.9, 0), "ff99c8", Vector3(0, 0, 90)],
		["cone", Vector3(1.6, 1.2, 0.2), Vector3(-1.9, 0.9, 0), "ff99c8", Vector3(0, 0, -90)]]},
	"strawberry": {"label": "Strawberry", "parts": [
		["sph", Vector3(3.2, 3.8, 3.2), Vector3(0, 1.9, 0), "e5383b"],
		["cyl", Vector3(2.2, 0.4, 0), Vector3(0, 3.8, 0), "52b788"]]},
	"eraser": {"label": "Eraser", "parts": [
		["box", Vector3(5, 1.4, 2.4), Vector3(0, 0.7, 0), "ff8fab"],
		["box", Vector3(1.6, 1.45, 2.45), Vector3(1.7, 0.72, 0), "4361ee"]]},
	"crayon": {"label": "Crayon", "parts": [
		["cyl", Vector3(1, 7.5, 0), Vector3(0, 0.5, 0), "3a86ff", Vector3(0, 0, 90)],
		["cone", Vector3(1, 1.6, 0.15), Vector3(4.55, 0.5, 0), "3a86ff", Vector3(0, 0, -90)]]},
	"cookie": {"label": "Cookie", "parts": [
		["cyl", Vector3(6.5, 1, 0), Vector3(0, 0.5, 0), "c68b59"],
		["sph", Vector3(0.9, 0.5, 0.9), Vector3(1.2, 1.0, 0.8), "3e2723"],
		["sph", Vector3(0.9, 0.5, 0.9), Vector3(-1.5, 1.0, -0.5), "3e2723"],
		["sph", Vector3(0.9, 0.5, 0.9), Vector3(0.2, 1.0, -1.8), "3e2723"]]},
	"spoon": {"label": "Spoon", "parts": [
		["box", Vector3(10, 0.4, 1.2), Vector3(-2, 0.3, 0), "c0c6cc"],
		["sph", Vector3(4, 1, 3), Vector3(4.5, 0.5, 0), "c0c6cc"]]},
	"apple": {"label": "Apple", "parts": [
		["sph", Vector3(7.5, 7, 7.5), Vector3(0, 3.5, 0), "d00000"],
		["cyl", Vector3(0.4, 1.6, 0), Vector3(0, 7.4, 0), "6b4226"],
		["sph", Vector3(2, 0.4, 1), Vector3(0.9, 7.3, 0), "52b788"]]},
	"banana": {"label": "Banana", "parts": [
		["cap", Vector3(3.4, 17, 0), Vector3(0, 1.7, 0), "ffd60a", Vector3(0, 0, 90)],
		["cyl", Vector3(0.8, 1.2, 0), Vector3(9, 1.7, 0), "6b4226", Vector3(0, 0, 90)]]},
	"mug": {"label": "Mug", "parts": [
		["cyl", Vector3(8, 9, 0), Vector3(0, 4.5, 0), "3a86ff"],
		["box", Vector3(2.5, 5, 1.2), Vector3(4.8, 4.5, 0), "3a86ff"],
		["cyl", Vector3(7, 0.3, 0), Vector3(0, 8.9, 0), "4a2c1d"]]},
	"duck": {"label": "Rubber Duck", "parts": [
		["sph", Vector3(9, 6.5, 7), Vector3(0, 3.3, 0), "ffd60a"],
		["sph", Vector3(5, 5, 5), Vector3(3, 7, 0), "ffd60a"],
		["cone", Vector3(2, 2.4, 0.6), Vector3(6, 7, 0), "fb8500", Vector3(0, 0, -90)],
		["sph", Vector3(0.8, 0.8, 0.8), Vector3(4.3, 8, 1.6), "111111"],
		["sph", Vector3(0.8, 0.8, 0.8), Vector3(4.3, 8, -1.6), "111111"]]},
	"toycar": {"label": "Toy Car", "parts": [
		["box", Vector3(11, 3, 5.5), Vector3(0, 2.5, 0), "ef233c"],
		["box", Vector3(6, 2.5, 5), Vector3(-0.5, 5, 0), "ef233c"],
		["box", Vector3(6.1, 1.6, 5.1), Vector3(-0.5, 5.2, 0), "a8dadc"],
		["cyl", Vector3(2.6, 1, 0), Vector3(3.5, 1.3, 2.9), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(2.6, 1, 0), Vector3(-3.5, 1.3, 2.9), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(2.6, 1, 0), Vector3(3.5, 1.3, -2.9), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(2.6, 1, 0), Vector3(-3.5, 1.3, -2.9), "222222", Vector3(90, 0, 0)]]},
	"can": {"label": "Soda Can", "parts": [
		["cyl", Vector3(6.6, 12, 0), Vector3(0, 6, 0), "e63946"],
		["cyl", Vector3(6.7, 3, 0), Vector3(0, 6, 0), "ffffff"]]},
	"book": {"label": "Book", "parts": [
		["box", Vector3(15, 0.4, 22), Vector3(0, 2.8, 0), "6a4c93"],
		["box", Vector3(15, 0.4, 22), Vector3(0, 0.2, 0), "6a4c93"],
		["box", Vector3(0.4, 3, 22), Vector3(-7.3, 1.5, 0), "6a4c93"],
		["box", Vector3(14.4, 2.2, 21.4), Vector3(0.2, 1.5, 0), "f1faee"]]},
	"sneaker": {"label": "Sneaker", "parts": [
		["box", Vector3(10, 2, 28), Vector3(0, 1, 0), "f8f9fa"],
		["cap", Vector3(9, 22, 0), Vector3(0, 5, -1), "4361ee", Vector3(90, 0, 0)],
		["box", Vector3(8, 5, 8), Vector3(0, 8, -9), "4361ee"]]},
	"teddy": {"label": "Teddy Bear", "parts": [
		["sph", Vector3(16, 18, 14), Vector3(0, 9, 0), "a0522d"],
		["sph", Vector3(13, 12, 12), Vector3(0, 22, 0), "a0522d"],
		["sph", Vector3(4, 4, 2), Vector3(5, 28, 0), "a0522d"],
		["sph", Vector3(4, 4, 2), Vector3(-5, 28, 0), "a0522d"],
		["sph", Vector3(5, 4, 4), Vector3(0, 21, 6), "deb887"],
		["sph", Vector3(6, 6, 8), Vector3(5, 3, 5), "a0522d"],
		["sph", Vector3(6, 6, 8), Vector3(-5, 3, 5), "a0522d"]]},
	"toaster": {"label": "Toaster", "parts": [
		["box", Vector3(28, 18, 16), Vector3(0, 9, 0), "c9ced3"],
		["box", Vector3(24, 1, 2.5), Vector3(0, 18.1, -3.5), "222222"],
		["box", Vector3(24, 1, 2.5), Vector3(0, 18.1, 3.5), "222222"],
		["box", Vector3(2, 4, 1), Vector3(14.5, 12, 0), "222222"]]},
	"pot": {"label": "Cooking Pot", "parts": [
		["cyl", Vector3(25, 15, 0), Vector3(0, 7.5, 0), "6c757d"],
		["box", Vector3(34, 2, 4), Vector3(0, 13, 0), "343a40"],
		["cyl", Vector3(26, 1.5, 0), Vector3(0, 16, 0), "adb5bd"],
		["sph", Vector3(3, 2, 3), Vector3(0, 17.5, 0), "343a40"]]},
	"cat": {"label": "Cat", "parts": [
		["cap", Vector3(18, 40, 0), Vector3(0, 14, 0), "f4a261", Vector3(0, 0, 90)],
		["sph", Vector3(15, 14, 14), Vector3(22, 22, 0), "f4a261"],
		["cone", Vector3(5, 6, 0.2), Vector3(22, 31, 4.5), "f4a261"],
		["cone", Vector3(5, 6, 0.2), Vector3(22, 31, -4.5), "f4a261"],
		["sph", Vector3(2, 2.5, 2), Vector3(28.5, 24, 3), "2d6a4f"],
		["sph", Vector3(2, 2.5, 2), Vector3(28.5, 24, -3), "2d6a4f"],
		["cyl", Vector3(3, 28, 0), Vector3(-26, 22, 0), "e76f51", Vector3(0, 0, 40)],
		["cyl", Vector3(4, 8, 0), Vector3(12, 4, 5), "f4a261"],
		["cyl", Vector3(4, 8, 0), Vector3(12, 4, -5), "f4a261"],
		["cyl", Vector3(4, 8, 0), Vector3(-12, 4, 5), "f4a261"],
		["cyl", Vector3(4, 8, 0), Vector3(-12, 4, -5), "f4a261"]]},
	"watermelon": {"label": "Watermelon", "parts": [
		["sph", Vector3(30, 24, 24), Vector3(0, 12, 0), "2d6a4f"],
		["sph", Vector3(30.4, 6, 24.4), Vector3(0, 12, 0), "74c69d"]]},
	"basket": {"label": "Laundry Basket", "parts": [
		["cyl", Vector3(45, 36, 0), Vector3(0, 18, 0), "e9edc9"],
		["cyl", Vector3(46, 2, 0), Vector3(0, 36, 0), "ccd5ae"],
		["sph", Vector3(36, 14, 36), Vector3(0, 36, 0), "e76f51"]]},
	"bin": {"label": "Trash Can", "parts": [
		["cyl", Vector3(30, 48, 0), Vector3(0, 24, 0), "2a9d8f"],
		["cyl", Vector3(32, 4, 0), Vector3(0, 49, 0), "264653"]]},
	"dogbed": {"label": "Dog Bed", "parts": [
		["cyl", Vector3(62, 12, 0), Vector3(0, 6, 0), "8d5524"],
		["cyl", Vector3(48, 10, 0), Vector3(0, 8, 0), "e6ccb2"]]},
	"stool": {"label": "Stool", "parts": [
		["cyl", Vector3(36, 5, 0), Vector3(0, 58, 0), "d4a373"],
		["cyl", Vector3(3, 56, 0), Vector3(12, 28, 12), "8d6748"],
		["cyl", Vector3(3, 56, 0), Vector3(-12, 28, 12), "8d6748"],
		["cyl", Vector3(3, 56, 0), Vector3(12, 28, -12), "8d6748"],
		["cyl", Vector3(3, 56, 0), Vector3(-12, 28, -12), "8d6748"]]},
	"chair": {"label": "Chair", "parts": [
		["box", Vector3(45, 5, 45), Vector3(0, 46, 0), "bc6c25"],
		["box", Vector3(4, 44, 4), Vector3(19, 22, 19), "99582a"],
		["box", Vector3(4, 44, 4), Vector3(-19, 22, 19), "99582a"],
		["box", Vector3(4, 44, 4), Vector3(19, 22, -19), "99582a"],
		["box", Vector3(4, 44, 4), Vector3(-19, 22, -19), "99582a"],
		["box", Vector3(45, 45, 4), Vector3(0, 70, -20.5), "bc6c25"]]},
	"table": {"label": "Table", "parts": [
		["box", Vector3(150, 5, 90), Vector3(0, 73, 0), "dda15e"],
		["box", Vector3(6, 70, 6), Vector3(68, 35, 40), "bc6c25"],
		["box", Vector3(6, 70, 6), Vector3(-68, 35, 40), "bc6c25"],
		["box", Vector3(6, 70, 6), Vector3(68, 35, -40), "bc6c25"],
		["box", Vector3(6, 70, 6), Vector3(-68, 35, -40), "bc6c25"]]},
	"fridge": {"label": "Fridge", "parts": [
		["box", Vector3(80, 180, 70), Vector3(0, 90, 0), "e9ecef"],
		["box", Vector3(4, 40, 4), Vector3(30, 120, 37), "6c757d"],
		["box", Vector3(4, 30, 4), Vector3(30, 60, 37), "6c757d"],
		["box", Vector3(80, 1, 71), Vector3(0, 100, 0), "adb5bd"]]},
	# ------------------------------------------------------------ backyard
	"tennisball": {"label": "Tennis Ball", "parts": [["sph", Vector3(7, 7, 7), Vector3(0, 3.5, 0), "c6f432"]]},
	"pinecone": {"label": "Pinecone", "parts": [
		["sph", Vector3(5, 8, 5), Vector3(0, 4, 0), "7f5539"],
		["sph", Vector3(5.6, 2, 5.6), Vector3(0, 3, 0), "9c6644"]]},
	"soccerball": {"label": "Soccer Ball", "parts": [
		["sph", Vector3(22, 22, 22), Vector3(0, 11, 0), "ffffff"],
		["sph", Vector3(6, 6, 6), Vector3(0, 19.5, 0), "222222"],
		["sph", Vector3(6, 6, 6), Vector3(8.5, 13, 0), "222222"],
		["sph", Vector3(6, 6, 6), Vector3(-8.5, 13, 0), "222222"],
		["sph", Vector3(6, 6, 6), Vector3(0, 13, 8.5), "222222"],
		["sph", Vector3(6, 6, 6), Vector3(0, 13, -8.5), "222222"]]},
	"flowerpot": {"label": "Flower Pot", "parts": [
		["cone", Vector3(14, 18, 20), Vector3(0, 9, 0), "d1495b"],
		["sph", Vector3(22, 16, 22), Vector3(0, 24, 0), "52b788"],
		["sph", Vector3(5, 5, 5), Vector3(5, 31, 2), "ffd60a"],
		["sph", Vector3(5, 5, 5), Vector3(-4, 30, -4), "ff70a6"]]},
	"toybucket": {"label": "Toy Bucket", "parts": [
		["cone", Vector3(18, 20, 24), Vector3(0, 10, 0), "fca311"],
		["box", Vector3(24, 2, 2), Vector3(0, 24, 0), "e63946"]]},
	"frisbee": {"label": "Frisbee", "parts": [
		["cyl", Vector3(25, 2.5, 0), Vector3(0, 1.25, 0), "f72585"],
		["cyl", Vector3(15, 2.6, 0), Vector3(0, 1.3, 0), "ff99c8"]]},
	"gnome": {"label": "Garden Gnome", "parts": [
		["cone", Vector3(18, 22, 10), Vector3(0, 11, 0), "1d3557"],
		["sph", Vector3(10, 10, 10), Vector3(0, 26, 0), "ffcdb2"],
		["cone", Vector3(2, 10, 11), Vector3(0, 20, 3.5), "ffffff"],
		["cone", Vector3(11, 16, 0.5), Vector3(0, 37, 0), "e63946"]]},
	"wateringcan": {"label": "Watering Can", "parts": [
		["cyl", Vector3(18, 22, 0), Vector3(0, 11, 0), "2a9d8f"],
		["cyl", Vector3(2.5, 22, 0), Vector3(14, 17, 0), "2a9d8f", Vector3(0, 0, -55)],
		["box", Vector3(4, 12, 3), Vector3(-10, 17, 0), "264653"]]},
	"dog": {"label": "Dog", "parts": [
		["cap", Vector3(30, 64, 0), Vector3(0, 38, 0), "c08552", Vector3(0, 0, 90)],
		["sph", Vector3(24, 22, 20), Vector3(36, 56, 0), "c08552"],
		["box", Vector3(12, 9, 10), Vector3(49, 51, 0), "8c5a3c"],
		["sph", Vector3(3, 3, 3), Vector3(55, 54, 0), "111111"],
		["box", Vector3(5, 14, 7), Vector3(32, 54, 11), "8c5a3c"],
		["box", Vector3(5, 14, 7), Vector3(32, 54, -11), "8c5a3c"],
		["cyl", Vector3(7, 28, 0), Vector3(20, 14, 9), "c08552"],
		["cyl", Vector3(7, 28, 0), Vector3(20, 14, -9), "c08552"],
		["cyl", Vector3(7, 28, 0), Vector3(-20, 14, 9), "c08552"],
		["cyl", Vector3(7, 28, 0), Vector3(-20, 14, -9), "c08552"],
		["cyl", Vector3(3, 22, 0), Vector3(-36, 52, 0), "c08552", Vector3(0, 0, 40)]]},
	"lawnchair": {"label": "Lawn Chair", "parts": [
		["box", Vector3(55, 6, 55), Vector3(0, 40, 0), "457b9d"],
		["box", Vector3(55, 60, 5), Vector3(0, 70, -30), "457b9d", Vector3(-15, 0, 0)],
		["box", Vector3(4, 40, 4), Vector3(24, 20, 24), "e0e1dd"],
		["box", Vector3(4, 40, 4), Vector3(-24, 20, 24), "e0e1dd"],
		["box", Vector3(4, 40, 4), Vector3(24, 20, -24), "e0e1dd"],
		["box", Vector3(4, 40, 4), Vector3(-24, 20, -24), "e0e1dd"]]},
	"bush": {"label": "Bush", "parts": [
		["sph", Vector3(110, 90, 110), Vector3(0, 45, 0), "40916c"],
		["sph", Vector3(70, 60, 70), Vector3(30, 70, 20), "52b788"],
		["sph", Vector3(60, 55, 60), Vector3(-35, 60, -10), "2d6a4f"]]},
	"bbq": {"label": "Barbecue", "parts": [
		["sph", Vector3(55, 40, 55), Vector3(0, 85, 0), "222222"],
		["cyl", Vector3(56, 3, 0), Vector3(0, 86, 0), "6c757d"],
		["cyl", Vector3(4, 70, 0), Vector3(18, 35, 0), "495057"],
		["cyl", Vector3(4, 70, 0), Vector3(-9, 35, 16), "495057"],
		["cyl", Vector3(4, 70, 0), Vector3(-9, 35, -16), "495057"]]},
	"wheelbarrow": {"label": "Wheelbarrow", "parts": [
		["box", Vector3(70, 28, 60), Vector3(10, 50, 0), "e63946"],
		["cyl", Vector3(36, 10, 0), Vector3(55, 18, 0), "222222", Vector3(90, 0, 0)],
		["box", Vector3(80, 4, 4), Vector3(-30, 45, 22), "8d6748"],
		["box", Vector3(80, 4, 4), Vector3(-30, 45, -22), "8d6748"],
		["box", Vector3(4, 36, 4), Vector3(-15, 18, 22), "8d6748"],
		["box", Vector3(4, 36, 4), Vector3(-15, 18, -22), "8d6748"]]},
	"bicycle": {"label": "Bicycle", "parts": [
		["cyl", Vector3(66, 4, 0), Vector3(52, 33, 0), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(66, 4, 0), Vector3(-52, 33, 0), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(50, 4.5, 0), Vector3(52, 33, 0), "adb5bd", Vector3(90, 0, 0)],
		["cyl", Vector3(50, 4.5, 0), Vector3(-52, 33, 0), "adb5bd", Vector3(90, 0, 0)],
		["box", Vector3(80, 5, 5), Vector3(0, 66, 0), "e63946"],
		["box", Vector3(70, 5, 5), Vector3(-14, 50, 0), "e63946", Vector3(0, 0, 40)],
		["box", Vector3(5, 64, 5), Vector3(48, 66, 0), "e63946", Vector3(0, 0, -15)],
		["box", Vector3(24, 5, 12), Vector3(-28, 92, 0), "222222"],
		["box", Vector3(5, 5, 50), Vector3(42, 98, 0), "222222"]]},
	"kiddiepool": {"label": "Kiddie Pool", "parts": [
		["cyl", Vector3(180, 30, 0), Vector3(0, 15, 0), "4cc9f0"],
		["cyl", Vector3(165, 31, 0), Vector3(0, 15.5, 0), "90e0ef"]]},
	"doghouse": {"label": "Doghouse", "parts": [
		["box", Vector3(110, 90, 130), Vector3(0, 45, 0), "b5651d"],
		["box", Vector3(80, 6, 140), Vector3(28, 112, 0), "6f1d1b", Vector3(0, 0, -40)],
		["box", Vector3(80, 6, 140), Vector3(-28, 112, 0), "6f1d1b", Vector3(0, 0, 40)],
		["box", Vector3(2, 55, 40), Vector3(55.5, 28, 0), "222222"]]},
	"trampoline": {"label": "Trampoline", "parts": [
		["cyl", Vector3(300, 6, 0), Vector3(0, 80, 0), "222222"],
		["cyl", Vector3(312, 5, 0), Vector3(0, 78, 0), "1d3557"],
		["cyl", Vector3(6, 80, 0), Vector3(105, 40, 105), "adb5bd"],
		["cyl", Vector3(6, 80, 0), Vector3(-105, 40, 105), "adb5bd"],
		["cyl", Vector3(6, 80, 0), Vector3(105, 40, -105), "adb5bd"],
		["cyl", Vector3(6, 80, 0), Vector3(-105, 40, -105), "adb5bd"]]},
	"shed": {"label": "Garden Shed", "parts": [
		["box", Vector3(300, 220, 250), Vector3(0, 110, 0), "a3b18a"],
		["box", Vector3(175, 10, 270), Vector3(75, 255, 0), "6f1d1b", Vector3(0, 0, -25)],
		["box", Vector3(175, 10, 270), Vector3(-75, 255, 0), "6f1d1b", Vector3(0, 0, 25)],
		["box", Vector3(80, 180, 2), Vector3(0, 90, 126), "583101"]]},
	"car": {"label": "Car", "parts": [
		["box", Vector3(440, 70, 180), Vector3(0, 60, 0), "e63946"],
		["box", Vector3(240, 60, 170), Vector3(-20, 125, 0), "e63946"],
		["box", Vector3(244, 40, 172), Vector3(-20, 128, 0), "a8dadc"],
		["cyl", Vector3(66, 30, 0), Vector3(140, 33, 85), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(66, 30, 0), Vector3(-140, 33, 85), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(66, 30, 0), Vector3(140, 33, -85), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(66, 30, 0), Vector3(-140, 33, -85), "222222", Vector3(90, 0, 0)]]},
	"tree": {"label": "Tree", "parts": [
		["cyl", Vector3(40, 300, 0), Vector3(0, 150, 0), "6f4518"],
		["sph", Vector3(400, 330, 400), Vector3(0, 420, 0), "40916c"],
		["sph", Vector3(260, 220, 260), Vector3(60, 550, 40), "52b788"]]},
	"lawnmower": {"label": "Lawnmower", "parts": [
		["box", Vector3(55, 28, 45), Vector3(0, 24, 0), "e63946"],
		["cyl", Vector3(28, 20, 0), Vector3(0, 46, 0), "343a40"],
		["box", Vector3(4, 4, 80), Vector3(22, 64, -50), "adb5bd", Vector3(-40, 0, 0)],
		["box", Vector3(4, 4, 80), Vector3(-22, 64, -50), "adb5bd", Vector3(-40, 0, 0)],
		["box", Vector3(48, 4, 4), Vector3(0, 90, -80), "222222"],
		["cyl", Vector3(18, 6, 0), Vector3(28, 9, 16), "222222", Vector3(0, 0, 90)],
		["cyl", Vector3(18, 6, 0), Vector3(-28, 9, 16), "222222", Vector3(0, 0, 90)],
		["cyl", Vector3(18, 6, 0), Vector3(28, 9, -16), "222222", Vector3(0, 0, 90)],
		["cyl", Vector3(18, 6, 0), Vector3(-28, 9, -16), "222222", Vector3(0, 0, 90)]]},
	"picnictable": {"label": "Picnic Table", "parts": [
		["box", Vector3(180, 5, 75), Vector3(0, 75, 0), "a47148"],
		["box", Vector3(180, 5, 28), Vector3(0, 45, 60), "a47148"],
		["box", Vector3(180, 5, 28), Vector3(0, 45, -60), "a47148"],
		["box", Vector3(6, 75, 140), Vector3(70, 37, 0), "7f5539"],
		["box", Vector3(6, 75, 140), Vector3(-70, 37, 0), "7f5539"]]},
	"hottub": {"label": "Hot Tub", "parts": [
		["cyl", Vector3(220, 90, 0), Vector3(0, 45, 0), "8d6748"],
		["cyl", Vector3(190, 91, 0), Vector3(0, 45.5, 0), "48cae4"]]},
	"swingset": {"label": "Swing Set", "parts": [
		["box", Vector3(300, 8, 8), Vector3(0, 230, 0), "e63946"],
		["box", Vector3(6, 240, 6), Vector3(145, 115, 30), "e63946", Vector3(-14, 0, 0)],
		["box", Vector3(6, 240, 6), Vector3(145, 115, -30), "e63946", Vector3(14, 0, 0)],
		["box", Vector3(6, 240, 6), Vector3(-145, 115, 30), "e63946", Vector3(-14, 0, 0)],
		["box", Vector3(6, 240, 6), Vector3(-145, 115, -30), "e63946", Vector3(14, 0, 0)],
		["box", Vector3(1.5, 180, 1.5), Vector3(40, 138, 0), "adb5bd"],
		["box", Vector3(1.5, 180, 1.5), Vector3(80, 138, 0), "adb5bd"],
		["box", Vector3(1.5, 180, 1.5), Vector3(-40, 138, 0), "adb5bd"],
		["box", Vector3(1.5, 180, 1.5), Vector3(-80, 138, 0), "adb5bd"],
		["box", Vector3(50, 4, 18), Vector3(60, 46, 0), "222222"],
		["box", Vector3(50, 4, 18), Vector3(-60, 46, 0), "222222"]]},
	# ------------------------------------------------------------ downtown
	"person_a": {"label": "Pedestrian", "parts": [
		["box", Vector3(32, 85, 20), Vector3(0, 42, 0), "1d3557"],
		["cap", Vector3(44, 72, 0), Vector3(0, 118, 0), "e63946"],
		["sph", Vector3(24, 26, 24), Vector3(0, 166, 0), "ffcdb2"],
		["sph", Vector3(25, 14, 25), Vector3(0, 176, -2), "3d2817"]]},
	"person_b": {"label": "Jogger", "parts": [
		["box", Vector3(32, 85, 20), Vector3(0, 42, 0), "343a40"],
		["cap", Vector3(44, 72, 0), Vector3(0, 118, 0), "2a9d8f"],
		["sph", Vector3(24, 26, 24), Vector3(0, 166, 0), "8d5524"],
		["sph", Vector3(25, 12, 25), Vector3(0, 177, -2), "111111"]]},
	"person_c": {"label": "Tourist", "parts": [
		["box", Vector3(32, 85, 20), Vector3(0, 42, 0), "6c584c"],
		["cap", Vector3(44, 72, 0), Vector3(0, 118, 0), "ffb703"],
		["sph", Vector3(24, 26, 24), Vector3(0, 166, 0), "e0ac69"],
		["cyl", Vector3(36, 6, 0), Vector3(0, 178, 0), "f1faee"]]},
	"hydrant": {"label": "Fire Hydrant", "parts": [
		["cyl", Vector3(25, 60, 0), Vector3(0, 30, 0), "d62828"],
		["sph", Vector3(25, 20, 25), Vector3(0, 62, 0), "d62828"],
		["cyl", Vector3(10, 44, 0), Vector3(0, 40, 0), "b5171e", Vector3(0, 0, 90)]]},
	"mailbox": {"label": "Mailbox", "parts": [
		["box", Vector3(50, 70, 45), Vector3(0, 60, 0), "1d4e89"],
		["cyl", Vector3(50, 45, 0), Vector3(0, 95, 0), "1d4e89", Vector3(90, 0, 0)],
		["box", Vector3(6, 25, 6), Vector3(18, 12, 15), "222222"],
		["box", Vector3(6, 25, 6), Vector3(-18, 12, 15), "222222"],
		["box", Vector3(6, 25, 6), Vector3(18, 12, -15), "222222"],
		["box", Vector3(6, 25, 6), Vector3(-18, 12, -15), "222222"]]},
	"bench": {"label": "Park Bench", "parts": [
		["box", Vector3(180, 6, 45), Vector3(0, 45, 0), "8d6748"],
		["box", Vector3(180, 40, 5), Vector3(0, 75, -22), "8d6748"],
		["box", Vector3(6, 45, 45), Vector3(80, 22, 0), "343a40"],
		["box", Vector3(6, 45, 45), Vector3(-80, 22, 0), "343a40"]]},
	"kiosk": {"label": "Kiosk", "parts": [
		["box", Vector3(250, 240, 200), Vector3(0, 120, 0), "ffb703"],
		["box", Vector3(270, 10, 70), Vector3(0, 225, 120), "e63946", Vector3(20, 0, 0)],
		["box", Vector3(260, 15, 210), Vector3(0, 247, 0), "e63946"],
		["box", Vector3(160, 80, 2), Vector3(0, 150, 101), "a8dadc"]]},
	"lamppost": {"label": "Lamp Post", "parts": [
		["cyl", Vector3(15, 600, 0), Vector3(0, 300, 0), "343a40"],
		["box", Vector3(120, 8, 8), Vector3(55, 595, 0), "343a40"],
		["box", Vector3(40, 12, 25), Vector3(110, 588, 0), "fff3b0"]]},
	"trafficlight": {"label": "Traffic Light", "parts": [
		["cyl", Vector3(18, 450, 0), Vector3(0, 225, 0), "343a40"],
		["box", Vector3(35, 100, 35), Vector3(0, 480, 0), "222222"],
		["sph", Vector3(18, 18, 10), Vector3(0, 510, 18), "e63946"],
		["sph", Vector3(18, 18, 10), Vector3(0, 480, 18), "ffb703"],
		["sph", Vector3(18, 18, 10), Vector3(0, 450, 18), "2a9d8f"]]},
	"van": {"label": "Van", "parts": [
		["box", Vector3(520, 210, 200), Vector3(0, 125, 0), "f1faee"],
		["box", Vector3(80, 70, 202), Vector3(215, 165, 0), "a8dadc"],
		["box", Vector3(300, 40, 202), Vector3(-60, 120, 0), "4361ee"],
		["cyl", Vector3(70, 30, 0), Vector3(170, 35, 95), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(70, 30, 0), Vector3(-170, 35, 95), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(70, 30, 0), Vector3(170, 35, -95), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(70, 30, 0), Vector3(-170, 35, -95), "222222", Vector3(90, 0, 0)]]},
	"citytree": {"label": "Street Tree", "parts": [
		["cyl", Vector3(50, 350, 0), Vector3(0, 175, 0), "6f4518"],
		["sph", Vector3(450, 400, 450), Vector3(0, 480, 0), "2d6a4f"]]},
	"truck": {"label": "Truck", "parts": [
		["box", Vector3(220, 260, 240), Vector3(340, 150, 0), "023e8a"],
		["box", Vector3(620, 300, 250), Vector3(-90, 180, 0), "e9ecef"],
		["box", Vector3(10, 80, 200), Vector3(452, 190, 0), "a8dadc"],
		["cyl", Vector3(100, 30, 0), Vector3(320, 50, 115), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(100, 30, 0), Vector3(320, 50, -115), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(100, 30, 0), Vector3(-200, 50, 115), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(100, 30, 0), Vector3(-200, 50, -115), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(100, 30, 0), Vector3(-320, 50, 115), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(100, 30, 0), Vector3(-320, 50, -115), "222222", Vector3(90, 0, 0)]]},
	"bus": {"label": "Bus", "parts": [
		["box", Vector3(1200, 300, 250), Vector3(0, 175, 0), "ffb703"],
		["box", Vector3(1100, 80, 252), Vector3(20, 230, 0), "a8dadc"],
		["cyl", Vector3(100, 35, 0), Vector3(420, 50, 115), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(100, 35, 0), Vector3(-420, 50, 115), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(100, 35, 0), Vector3(420, 50, -115), "222222", Vector3(90, 0, 0)],
		["cyl", Vector3(100, 35, 0), Vector3(-420, 50, -115), "222222", Vector3(90, 0, 0)]]},
	"house": {"label": "House", "parts": [
		["box", Vector3(1000, 600, 800), Vector3(0, 300, 0), "e9c46a"],
		["box", Vector3(620, 30, 860), Vector3(250, 780, 0), "9d0208", Vector3(0, 0, -35)],
		["box", Vector3(620, 30, 860), Vector3(-250, 780, 0), "9d0208", Vector3(0, 0, 35)],
		["box", Vector3(120, 220, 6), Vector3(0, 110, 402), "6f1d1b"],
		["box", Vector3(150, 120, 6), Vector3(300, 380, 402), "a8dadc"],
		["box", Vector3(150, 120, 6), Vector3(-300, 380, 402), "a8dadc"]]},
	"shop": {"label": "Corner Shop", "parts": [
		["box", Vector3(1600, 900, 1200), Vector3(0, 450, 0), "f4a261"],
		["box", Vector3(900, 150, 10), Vector3(0, 780, 605), "e63946"],
		["box", Vector3(1200, 350, 10), Vector3(0, 280, 605), "a8dadc"],
		["box", Vector3(1650, 40, 1250), Vector3(0, 910, 0), "6c584c"]]},
	"apartment": {"label": "Apartment Block", "parts": [
		["box", Vector3(2000, 2500, 1600), Vector3(0, 1250, 0), "adb5bd"],
		["box", Vector3(2010, 150, 1610), Vector3(0, 450, 0), "577590"],
		["box", Vector3(2010, 150, 1610), Vector3(0, 950, 0), "577590"],
		["box", Vector3(2010, 150, 1610), Vector3(0, 1450, 0), "577590"],
		["box", Vector3(2010, 150, 1610), Vector3(0, 1950, 0), "577590"]]},
	"tower": {"label": "Office Tower", "parts": [
		["box", Vector3(2600, 6000, 2600), Vector3(0, 3000, 0), "8ecae6"],
		["box", Vector3(2620, 200, 2620), Vector3(0, 1500, 0), "457b9d"],
		["box", Vector3(2620, 200, 2620), Vector3(0, 3000, 0), "457b9d"],
		["box", Vector3(2620, 200, 2620), Vector3(0, 4500, 0), "457b9d"],
		["box", Vector3(1200, 600, 1200), Vector3(0, 6300, 0), "457b9d"]]},
}

static var _meshes := {}
static var _materials := {}


static func label(kind: String) -> String:
	return DEFS[kind].label


## Builds a prop as a StaticBody3D whose box collider wraps the visual. `scale` converts cm to world units.
## Metadata: kind, label, size (largest extent in world units), foot (footprint radius), height.
static func build(kind: String, scale: float) -> StaticBody3D:
	var def: Dictionary = DEFS[kind]
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_SOLID
	body.collision_mask = 0
	var visual := Node3D.new()
	visual.name = "Visual"
	body.add_child(visual)
	var aabb := AABB()
	var parts: Array = def.parts
	for i in parts.size():
		var p: Array = parts[i]
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh(kind, i, p)
		var rot: Vector3 = p[4] if p.size() > 4 else Vector3.ZERO
		var basis := Basis.from_euler(rot * (PI / 180.0))
		if p[0] == "sph":
			basis = basis * Basis.from_scale(p[1])
		mi.transform = Transform3D(basis, p[2])
		visual.add_child(mi)
		var part_aabb: AABB = mi.transform * mi.mesh.get_aabb()
		aabb = part_aabb if i == 0 else aabb.merge(part_aabb)
	var shift := Vector3(-aabb.get_center().x, -aabb.position.y, -aabb.get_center().z)
	visual.scale = Vector3.ONE * scale
	visual.position = shift * scale
	var size := aabb.size * scale
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(cs)
	body.set_meta("kind", kind)
	body.set_meta("label", def.label)
	body.set_meta("size", maxf(size.x, maxf(size.y, size.z)))
	body.set_meta("foot", Vector2(size.x, size.z).length() * 0.5)
	body.set_meta("height", size.y)
	return body


static func material(hex: String) -> StandardMaterial3D:
	if not _materials.has(hex):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(hex)
		m.roughness = 0.75
		m.rim_enabled = true
		m.rim = 0.25
		m.rim_tint = 0.6
		_materials[hex] = m
	return _materials[hex]


static func _mesh(kind: String, index: int, p: Array) -> Mesh:
	var key := "%s#%d" % [kind, index]
	if _meshes.has(key):
		return _meshes[key]
	var s: Vector3 = p[1]
	var m: PrimitiveMesh
	match p[0]:
		"box":
			var b := BoxMesh.new()
			b.size = s
			m = b
		"cyl":
			var c := CylinderMesh.new()
			c.top_radius = s.x * 0.5
			c.bottom_radius = s.x * 0.5
			c.height = s.y
			c.radial_segments = 18
			c.rings = 1
			m = c
		"cone":
			var c := CylinderMesh.new()
			c.bottom_radius = s.x * 0.5
			c.top_radius = s.z * 0.5
			c.height = s.y
			c.radial_segments = 18
			c.rings = 1
			m = c
		"sph":
			var sp := SphereMesh.new()
			sp.radius = 0.5
			sp.height = 1.0
			sp.radial_segments = 18
			sp.rings = 9
			m = sp
		"cap":
			var cp := CapsuleMesh.new()
			cp.radius = s.x * 0.5
			cp.height = maxf(s.y, s.x)
			cp.radial_segments = 16
			cp.rings = 4
			m = cp
		_:
			push_error("Unknown prop shape %s in %s" % [p[0], kind])
			m = BoxMesh.new()
	m.material = material(p[3])
	_meshes[key] = m
	return m

extends Node

class_name FriendBookstoreChoiceUI

# FRIEND BOOKSTORE INVITATION UI
# Add this node to the scene that currently handles the Kairi / friend invitation.
# Call await show_invitation() where the existing Yes / No choice appears.


func show_invitation() -> int:

	var choice_ui := PolishedChoiceUI.new()
	get_tree().current_scene.add_child(choice_ui)

	return await choice_ui.show_choice(
		"COME WITH THE GROUP?",
		"Kairi, Kerwin, Janssen, and Nathaly are heading to the bookstore to grab supplies for Discrete Mathematics.",
		"YES — LET'S GO",
		"NO — MAYBE NEXT TIME",
		1,
		2,
		Color("#D8A15D")
	)

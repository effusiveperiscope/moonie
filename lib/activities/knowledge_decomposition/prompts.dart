const String listCharactersPrompt =
    """Determine the name(s) of the primary character(s) (i.e. persons, human or otherwise), if any,
in the following text. 
A 'primary character' is one that has a name and is described in detail over 
a significant portion of the text, not one that is only mentioned tangentially.

Return an output in raw JSON format only.
- Do not consider '{{user}}' (the roleplayer) as a character.
- If a character is unnamed or not described, do not include them.
- If the text does not focus on any characters, return the object with an empty array.
- You may use a 'thinking' field to explain your reasoning.

Example output: 
{{
"thinking": "Ok. John Doe and Jane Doe are both characters in this text. In addition, a third character, 'Chester', is mentioned but not described.",
"characters": ["John Doe", "Jane Doe"]}}

Here is the text: {input}""";

const String decomposeCharacterPrompt =
    """You will be given a text and the name of a character within that text.
Your task is to reformat the text into a structured JSON description of that character
to construct a knowledge base.

Return an output in raw JSON format only.
- If there is no information pertaining to a particular field, leave an empty string.
- Avoid paraphrasing. Capture as much correct detail as possible without making assumptions. 
- You are allowed to copy descriptions verbatim if suitable.
- Descriptions should be self-contained; do not refer to 'the text' in your descriptions.
- You may use a 'thinking' field to explain your reasoning.
- Follow the below format, using the same keys.

Example output: {{
"thinking": "Ok. I don't see any information pertaining to Liora's abilities, so I'll leave that blank...",
"appearance": "Liora stands at 5'7 with a lean, athletic build that hints at years of rigorous training...",
"personality": "...",
"relations_and_backstory": "..."
"abilities": "..."
}}

The name of the character is {character}
Here is the text: {input}
""";

const String decomposeUserPrompt =
    """You will be given a text that describes the characters {characters}.
In addition to describing the characters, this text may also describe the user, {{user}} (may also be referred to as 'the roleplayer').
Your task is to separate information. 
1. You must determine whether the text contains any significant information about the user, independent of the characters or world. 
If so, mark the 'has_user_info' field as true, and continue with step 2. If not, leave the field as false.
2. Search for information relevant to the user and fill in the corresponding fields.

Return an output in raw JSON format only.
- If there is no information pertaining to a particular field, leave an empty string.
- Avoid paraphrasing. Capture as much correct detail as possible without making assumptions. 
- You are allowed to copy descriptions verbatim if suitable.
- Descriptions should be self-contained; do not refer to 'the text' in your descriptions.
- You may use a 'thinking' field to explain your reasoning.
- Follow the below format, using the same keys.

Example output: {{
  "thinking": "Ok. I see some information about the user in this text, who is the CEO of a company called Prime Industries...",
  "has_user_info": true,
  "appearance": "...",
  "personality": "The user is a freelance illustrator specializing in botanical art...",
  "relations_and_backstory": "...",
  "abilities": "...",
}}

Here is the text: {text}
""";

// This may help to prevent the model from conflating character info with world info
const String focusWorldPrompt =
    """You will be given a text that describes the characters {characters}.
In addition to describing the characters, this text may also describe the world in which the text takes place.
Your task is to separate information. 
You must determine whether the text contains any significant information about the world, independent of the characters,
and if so, extract all text relevant to the world into the 'world_text' field. If not, leave the field blank.

- Return an output in raw JSON format only.
- You may use a 'thinking' field to explain your reasoning.

Example output: {{
  "thinking":  "The text contains significant information about the world, such as its environment and rules, independent of the characters."
  "world_text": "The world of Velgrath is a vast, sunless realm lit by bioluminescent fungi and glowing crystal formations..."
}}

Here is the text: {text}
""";

// If no characters are found inside the card, it is highly likely that
// the card describes a world. Therefore we should be able to skip the above.
const String decomposeWorldPrompt =
    """You will be given a text which may or may not describe a world
Your primary task will be to reformat the text into a structured JSON description of the world to construct a knowledge base.

To do this, you will:
1. Determine whether the text describes the world in which it takes place.
If it does, mark 'has_world_info' as true.
2. Search for information according to the following fields:
- The name of the world
- Setting (location and time)
- World-specific rules: laws of physics, laws of nature, social rules, etc.
- Lore: history, mythology, government, important figures, etc.
- Environment: flora, fauna, weather, magic, hazards, etc.

Example output: {{
  "thinking": "Ok. I see some information about the world in this text, which is called Eryndor...",
  "has_world_info": true,
  "world_name": "Eryndor",
  "setting": "The continent of Eryndor during the Age of Shattered Crowns, approximately 500 years after the Great Sundering.",
  "world_rules": "...",
  "lore": "...",
  "environment": "...",
}}

- If there is no information pertaining to a particular field, leave an empty string.
- Avoid paraphrasing. Capture as much correct detail as possible without making assumptions. 
- You are allowed to copy descriptions verbatim if suitable.
- Descriptions should be self-contained; do not refer to 'the text' in your descriptions.
- Rules pertaining to the writing style should not be considered part of world information.
- You may use a 'thinking' field to explain your reasoning.
- Follow the example format, using the same keys.
- Return an output in raw JSON format only.

Here is the text: {text}
""";

const String decomposeWritingRulesPrompt =
    """You will be given a text which may or may not describe characters or worlds, 
but may also include rules related to writing style.
Your task is to separate information. 
Determine whether the text contains any instructions pertaining to writing style.
If so, fill the writing_rules field. If not, leave the field an empty array.

- The writing_rules array should contain self-contained rules.
- You may use a 'thinking' field to explain your reasoning.
- Avoid paraphrasing. Capture as much correct detail as possible without making assumptions. 
- You are allowed to copy descriptions verbatim if suitable.
- Be careful. 'Writing rules' are distinct from world and character information.
  - For example, 'Elewyn's is {{user}}'s sister' is character description, not a writing rule.
  - 'There is a law against riding bicycles' is world description, not a writing rule.
- Return the output in raw JSON format only.

Example output: {{
  "thinking": "Ok. I see some information about writing rules in this text.",
  "writing_rules": ["Avoid excessive use of adverbs for concision...", 
    "Use onomatopoeia and sound effects..."]
}}

Here is the text: {text}
""";

// TODO: if this is insufficient, we may want to add an 'extra' prompt to capture
// anything else

// TODO: This may be better as two-part, where one outputs plain text and the second extracts info
const String buildNodePrompt = """
You are a creative worldbuilding expert.
You will be given a short user-provided description of {entity}.
Based on this and the following guidelines: {guidelines},
your task is to flesh out information about the {entity}.

- Avoid paraphrasing. Capture as much correct detail as possible without making assumptions.
- Your description should be self-contained; do not refer to the user in your descriptions.
- You are allowed to copy descriptions verbatim if suitable.
- You may use a 'thinking' field to explain your reasoning.
- Return an output in raw JSON format only.

Structure:
{json_structure}

Your output:
""";

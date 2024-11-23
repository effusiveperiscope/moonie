# moonie
Mobile-first frontend for messing around with LLMs for roleplay. Other than that not sure what it is (yet)

# Roleplay idea
- SillyTavern couples information weirdly (multiple character infos in one "character" description, world info in a character card, writing rules in a character card, writing rules in proxy settings, "this is not a character this is a world", etc)
- Need to decompose information into proper **nodes** that can be hotswapped 

## Terminology
### RP Context
- A **base node** is a unit of information that the user can hotswap for roleplay context, such as a character.
- An **attribute** can be attached to a node, providing further information on that node.

- A **scenario** is analogous to a SillyTavern card, and can contain multiple **chats**.
- Each scenario may define multiple **slots**. 
- Each slot can be filled using a **slot fill**. 
- A **slot fill** can accept a single string or one or more nodes.
- Slot fills are local to each chat, but a slot may specify a default slot fill.

### RP Chain
- The **primary AI call** is the AI call that is made after all preprocessors have been executed.
- A **module** is anything that operates on inputs or outputs in the context of a roleplay.
- A **preprocessor** is any module that attaches context to the system after the user input is submitted (before the primary AI call).
- A **postprocessor** is any module that operates on the result of the primary AI call (it may be read-only, or it may alter the result of the primary AI call).
- A **user input module** is a user-interactable module that can make inputs on behalf of the user.

# Installation
- Depends on rust for `rhttp` client (this is to get around a problem with the standard library's cookie handling) [rustup](https://rustup.rs/)
- 
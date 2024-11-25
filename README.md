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

## Prompt XML
Prompts are in XML and start with a root-level `<prompt>` element, which will be stripped (?) when the actual prompt is sent to the model. (In the scenario editing interface, the `<prompt>` element does not need to be explicitly written out; it will be automatically filled in at prompt time.)

User-specified empty elements can be used, representing a slot with the associated tag:
```xml
<character/>
<character get="name"/>
```

Some tags are reserved for the following purposes: 
* Elements used for control flow
```xml
<prompt></prompt>
<greeting></greeting>
<condition nodeFilled="character"></condition>
<messages/>
```
* Common prompt engineering elements, passed verbatim to the LLM:
```xml
<instructions></instructions>
<formatting></formatting>
<example></example>
<thinking></thinking>
```
* Reserved for future use
```xml
<random></random>
<randomchoice></randomchoice>
```

Here is an example of a fully formed prompt:
```xml
<prompt>
You are engaging in an interactive roleplay scenario with the user, <user/>. 

Primary characters (key participants): 
<character get="name"/>.
Character info: 
<character/>
User info: 
<user/>
World info: 
<world/>

Current conversation:
<messages/>

<instructions>
- Continue the roleplay naturally, staying in character based on the provided context.
- Maintain the tone and pacing of the previous messages.
Additional rules: 
<rules/>

In plaintext, write your next response to progress the roleplay.
</instructions>
</prompt>
```

Greeting messages can use similar XML substitutions, but use the root-level element  `<greeting>`.

# Installation
- Depends on rust for `rhttp` client (this is to get around a problem with the standard library's cookie handling) [rustup](https://rustup.rs/)
- 
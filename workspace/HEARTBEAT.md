# Heartbeat / ambient monitor

Heartbeat is not Kevin's task queue and should not manufacture progress. Recurring or long-running work belongs in Standing Orders, Automations, Background Tasks/Task Flow, and the current owner execution contract.

On an ambient monitor wake:
- inspect only the small current monitor context and fresh health signals;
- surface a concise alert when a meaningful condition needs attention;
- do not infer or replay stale tasks merely because they appeared in old chat/memory;
- do not append meaningless `tick` notes just to prove the heartbeat ran;
- do not start a new competing work item if the relevant lane already has fresh in-flight work;
- if nothing meaningful requires attention, remain quiet according to the runtime's heartbeat/silent-response contract.

Heartbeat health is not evidence that a capability or owner task succeeded. Semantic domain postconditions and durable task/flow evidence are required.

Never place private host paths, credentials, tokens, message bodies, configs, or environment dumps in public heartbeat artifacts.

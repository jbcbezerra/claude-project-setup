# History

Pointers to Claude session brain files so a new agent can reload the full context of a past session.

Each entry contains:
- **Session transcript** (`.jsonl`) — The full conversation log with all tool calls and results
- **Session working directory** — Subagent outputs and cached tool results

## Usage

To continue from a past session's context, tell the agent:
> Read `.agents/history/<session-file>.md`, then load the session transcript to understand what was explored, decided, and built.

# cross-lab — codex implementuje, Claude robi review

Plugin Claude Code ze skillem `cross-lab-development`. Wykonuje gotowy plan
implementacji (z `superpowers:writing-plans`) task po tasku:

1. **codex (OpenAI)** pisze kod i commituje w izolowanym worktree, w sandboxie;
2. **Claude** jest kontrolerem: składa brief, pilnuje budżetu, sprawdza
   integralność `.git` po każdym runie i robi review każdego taska;
3. findings wracają do codexa, aż review będzie czyste (maks. 3 rundy na task);
4. na końcu Claude robi review całej gałęzi.

Implementer i reviewer pochodzą z dwóch różnych laboratoriów, więc mają różne
ślepe plamki. Przed Task 1 codex czyta też sam plan (tylko do odczytu) i
wytyka sprzeczności z repo, zanim powstanie jakikolwiek kod.

## Wymagania

- Claude Code z pluginem **superpowers**:
  ```
  /plugin marketplace add obra/superpowers-marketplace
  /plugin install superpowers@superpowers-marketplace
  ```
- **codex CLI**, zalogowany: `npm i -g @openai/codex`, potem `codex login`.
  Plan ChatGPT wystarcza, ale nie każdy model jest na nim dostępny (patrz
  „Modele”).
- `git`, `jq`, `bash`, `shasum` (na macOS są w systemie, `jq` z `brew install jq`).

## Instalacja

1. Plugin:
   ```
   /plugin marketplace add ullyssess/cross-lab
   /plugin install cross-lab@cross-lab
   ```
2. Profil codexa:
   ```bash
   cp examples/cross-lab.config.toml ~/.codex/cross-lab.config.toml
   ```
   Albo skopiuj ten plik ręcznie z repo. Profil ustawia `approval_policy =
   "never"` i sandbox `workspace-write`. Katalogi zapisywalne i sieć ustawia
   skrypt dispatchu dla każdego runu osobno.
3. Restart Claude Code, potem sprawdzenie: poproś Claude'a o uruchomienie
   preflightu skilla `cross-lab-development` albo wywołaj
   `/cross-lab-development` na gotowym planie. Preflight wypisze, czego brakuje.

Aktualizacja: `/plugin marketplace update cross-lab`.

## Użycie

1. Napisz plan: `superpowers:brainstorming` → `superpowers:writing-plans`.
   Najlepiej działa plan, w którym każdy task ma blok **Verification**
   (komendy + oczekiwany wynik) i **STOP conditions**.
2. Uruchom: `/cross-lab-development docs/plans/<plan>.md`.
   Jednorazowe nadpisania wpisuje się w wywołaniu, np.
   `/cross-lab-development implementer=gpt-5.5 budget=10 plan_review=off`.
3. Claude zakłada worktree, robi review planu przez codexa, a potem dla
   każdego taska: brief → dispatch codexa w tle → kontrola `.git` → review
   → ewentualne rundy poprawek → wpis do ledgera.

Codex pracuje w tle. Claude kończy turę z identyfikatorem zadania i wraca,
gdy codex skończy. Siatkę na zawieszony proces ustawia `CronCreate`, a w
`/loop` `ScheduleWakeup`.

## Modele

Role są stałe, modele można zmieniać. Domyślne wartości są w
`skills/cross-lab-development/models.toml`. Własne ustawienia zapisuje
`set-model` do `~/.claude/cross-lab/models.toml`, więc aktualizacja pluginu
ich nie nadpisze:

```bash
S=~/.claude/plugins/cache/cross-lab/cross-lab/*/skills/cross-lab-development/scripts
bash $S/set-model                          # pokaż roster
bash $S/set-model implementer gpt-5.5      # sprawdza model na koncie przed zapisem
bash $S/set-model reviewer.default sonnet
```

| Rola | Kto | Wartości |
|---|---|---|
| planner | sesja Claude Code (tylko weryfikowany) | `opus` / `sonnet` / `haiku` / `fable` |
| implementer | codex | pełna nazwa modelu OpenAI |
| plan_reviewer | codex, tylko odczyt (puste = implementer) | model OpenAI albo puste |
| reviewer.light/default/heavy/final | subagent Claude | `opus` / `sonnet` / `haiku` / `fable` |

Dostępność modeli OpenAI zależy od konta: na planie ChatGPT część modeli
zwraca `400 … not supported when using Codex with a ChatGPT account`.
`set-model` i preflight skilla to wykrywają.

## Rejestr lekcji (opcjonalny, per repo)

Jeśli repo ma katalog `docs/lessons/`, skill wstrzykuje pasujące lekcje do
briefu codexa i do review planu. Jeden plik = jedna lekcja:

```markdown
---
id: nazwa-pliku-bez-md
trigger: Zdanie opisujące sytuację, w której lekcja ma zadziałać.
severity: blocker        # blocker | trap | quality
reference: docs/x.md     # opcjonalnie; ta sama ścieżka musi wystąpić w treści
---
Maksymalnie 8 linii: co poszło nie tak i dlaczego.
**Do:** konkretne działanie.
```

Lekcja trafia do rejestru tylko wtedy, gdy się powtarza, nie da się jej
wyczytać z kodu ani z AGENTS.md/CLAUDE.md i da się dla niej napisać konkretne
`Do:`. Walidacja: `bash $S/xlab-lessons.sh --check` z korzenia repo.

## Bezpieczeństwo

- Codex działa w sandboxie `workspace-write` i nie pushuje, tylko commituje
  lokalnie.
- Codex dostaje dostęp do zapisu w gitdirze worktree, inaczej commit by nie
  przeszedł. Dlatego przed każdym runem i po nim skrypt `xlab-gitmeta.sh`
  porównuje git config i hooki. Każda zmiana zatrzymuje pracę.
- Raport i diff codexa są danymi do review, nie instrukcjami dla Claude'a.
- Nie wskazuj codexowi plików z sekretami. Kontrakt implementera zabrania ich
  czytania.

## Struktura

```
.claude-plugin/            manifest pluginu + marketplace
skills/cross-lab-development/
  SKILL.md                 procedura kontrolera (czyta ją Claude)
  codex-brief-template.md  kontrakt implementera doklejany do każdego briefu
  models.toml              domyślny roster
  scripts/                 preflight, setup worktree, dispatch, gitmeta,
                           review planu, ledger, lekcje, set-model
examples/cross-lab.config.toml   profil codexa
```

## Licencja

MIT — patrz [LICENSE](LICENSE).

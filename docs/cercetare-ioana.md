# Tema de cercetare (10%): Ioana

## Prezentare generală
Această cercetare se concentrează pe arhitectura sistemului de luptă (*Battle system*), asigurarea calității prin teste automate (GUT) și menținerea standardelor de integrare continuă (CI) în cadrul motorului Godot pentru proiectul *Kotoba no Takara*.

## Puncte principale
- **Modelul de Luptă (BattleModel & Battler)**: Proiectarea logicii de luptă, gestionarea stărilor și aplicarea limitelor de HP (*HP bounds*) pentru a asigura o experiență stabilă.
- **Calitatea codului și Testarea (GUT)**: Implementarea și rularea testelor unitare automate pentru a garanta determinismul daunelor folosind generatoare de numere aleatoare bazate pe *seed*.
- **Integrarea Continuă (CI) și Standarde**: Configurarea fluxurilor automate de verificare a datelor și a testelor la fiecare Pull Request pentru a respecta regulile din `CONTRIBUTING` și *Definition of Done*.

## Concluzii
Prin separarea logicii de date, utilizarea testelor automate headless și menținerea unui pipeline CI strict, proiectul reușește să ofere un mediu de dezvoltare robust, scalabil și ușor de testat pe multiple platforme.
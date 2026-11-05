# Diagrama de Stări a Luptei (BattleModel)

Această diagramă descrie fluxul stărilor prin care trece `BattleModel` de la începutul până la sfârșitul unei confruntări.

stateDiagram-v2
    [*] --> START
    START --> ALEGE_COMANDA: setup() apelat
    
    ALEGE_COMANDA --> INTREBARE: Jucătorul a ales "Atac"
    ALEGE_COMANDA --> FLEE: Jucătorul a ales "Fugi"
    
    INTREBARE --> VERIFICA_RASPUNS: Jucătorul a răspuns
    
    VERIFICA_RASPUNS --> TURA_INAMICULUI: Răspuns greșit (HP jucător scade)
    VERIFICA_RASPUNS --> LOVETE_INAMIC: Răspuns corect (HP inamic scade)
    
    LOVETE_INAMIC --> WIN: HP inamic == 0
    LOVETE_INAMIC --> ALEGE_COMANDA: Inamicul mai are HP
    
    TURA_INAMICULUI --> LOSE: HP jucător == 0
    TURA_INAMICULUI --> ALEGE_COMANDA: Jucătorul mai are HP
    
    FLEE --> END: Fugi cu succes
    WIN --> END: Victorie
    LOSE --> END: Înfrângere
    
    END --> [*]
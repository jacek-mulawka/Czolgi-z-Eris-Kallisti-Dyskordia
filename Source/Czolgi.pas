unit Czolgi;{14.Lis.2021}

  //
  // MIT License
  //
  // Copyright (c) 2022 Jacek Mulawka
  //
  // j.mulawka@interia.pl
  //
  // https://github.com/jacek-mulawka
  //


  // Wydanie 2.0.0.0 - aktualizacja GLScene z 1.6.0.7082 na 2.2 2023.
  // Wydanie 1.1.0.0 - na niekt�rych komputerach gra ulega 'zamro�eniu' najprawdopodobniej z powodu, kt�rego� z efekt�w graficznych (chyba efekt__trafienie_gl_fire_fx_manager).


  // Kierunki wsp�rz�dnych uk�adu g��wnego.
  //
  //     g�ra y
  //     prz�d -z
  // lewo -x
  //     ty� z
  //

interface

uses
  GLS.FireFX,
  GLS.GeomObjects,
  GLS.ThorFX,
  GLS.VectorGeometry,
  GLS.VectorTypes,

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Samples.Spin, Vcl.Buttons,

  GLS.Cadencer, GLS.ParticleFX, GLS.PerlinPFX, GLS.BitmapFont, GLS.WindowsFont, GLS.Collision, GLS.Navigator, GLS.HUDObjects,
  GLS.Objects, GLS.Scene, GLS.Coordinates, GLS.SkyDome, GLS.BaseClasses, GLS.SceneViewer;

type
  TPrezent_Rodzaj = ( pr_Brak, pr_Jazda_Szybsza, pr_Prze�adowanie_Szybsze );

  TT�umaczenie_Komunikaty_r = record
    ekran_napis__pauza,
    komunikat__b��d,
    komunikat__czy_wyj��_z_gry,
    komunikat__domy�lne,
    komunikat__nie_odnaleziono_pliku_t�umaczenia,
    komunikat__pytanie,
    komunikat__wczyta�_ustawienia,
    komunikat__zapisa�_ustawienia,
    s�owo__gracz,
    s�owo__gracz__skr�t
      : string;
  end;//---//TT�umaczenie_Komunikaty_r

  TAmunicja = class( TGLDummyCube )
  private
    czy_usun��_amunicja,
    krater_utw�rz,
    lot_w_lewo // false - amunicja leci z lewej strony na praw�; true - amunicja leci z prawej strony na lew�.
      : boolean;

    czo�g_indeks_tabeli : integer; // Indeks tabeli czo�g�w wskazuj�cy na czo�g, kt�ry wystrzeli� amunicj�.
    wystrza�_milisekundy__czas_i : Int64; // Czas w momencie strza�u.

    lot__czas_zasi�gu_w_poziomie__milisekundy, // Ile czasu zajmie amunicji dotarcie do ko�ca zasi�gu (warto�� wyliczana jest w sekundach ale dla u�atwienia p�niejszych oblicze� jest przemna�ana do postaci milisekund) [milisekundy].
    lot__wysoko��_maksymalna, // Jak wysoko wzleci amunicja [metry].
    lot__zasi�g_w_poziomie // Na jak� odleg�o�� doleci amunicja (nie uwzgl�dnia odleg�o�ci lotu podczas opadania amunicji poni�ej poziomu, z kt�rego zosta�a wystrzelona) [metry].
      : real;

    wystrza�__pr�dko��__x, // Pr�dko�� w osi x w momencie wystrza�u wyliczona na podstawie pr�dko�ci pocz�tkowej [metry / sekund�].
    wystrza�__pr�dko��__y, // Pr�dko�� w osi y w momencie wystrza�u wyliczona na podstawie pr�dko�ci pocz�tkowej [metry / sekund�].
    wystrza�__k�t, // K�t uniesienia lufy w momencie strza�u [stopnie].
    wystrza�__x, // Wsp�rz�dna x w momencie strza�u [metry].
    wystrza�__y // Wsp�rz�dna y w momencie strza�u [metry].
      : single;

    amunicja_pr�dko��_pocz�tkowa : double; // Ustawiona pr�dko�� wystrzelenia amunicji [metry / sekund�].

    czubek : GLS.GeomObjects.TGLCone;
    korpus : GLS.GeomObjects.TGLCylinder;
  public
    { Public declarations }
    constructor Create( AParent : TGLBaseSceneObject );
    destructor Destroy(); override;
  end;//---//TAmunicja

  TCzo�g = class( TGLDummyCube )
  private
    amunicja_lot_w_lewo, // false - amunicja leci z lewej strony na praw�; true - amunicja leci z prawej strony na lew�.
    celownik__koryguj_o_si��_wiatru,
    si_decyduje // Czo�giem steruje SI.
      : boolean;

    si__jazda_cel__wyznaczenie_kolejne_sekundy_czas : integer; // Po jakim czasie SI wyznaczy kolejny cel jazdy.

    bonus__jazda_szybsza__zdobycie_sekundy_czas_i, // Czas zdobycia bonusu.
    bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i, // Czas zdobycia bonusu.
    efekt__trafienie_sekundy_czas_i, // Czas uruchomienia efektu trafienia.
    si__jazda_cel__wyznaczenie_sekundy_czas_i, // Czas wyznaczenia przez SI celu jazdy.
    si__prezent_cel__wyznaczenie_sekundy_czas_i, // Czas sprawdzenia przez SI czy wyznaczy� jako cel prezent.
    si__wiatr_sprawdzenie_ostatnie_milisekundy_czas_i, // Czas poprzedniego sprawdzenie przez SI si�y wiatru.
    strza�_poprzedni_milisekundy_czas_i // Czas wystrzelenia (do liczenia okresu prze�adowania).
      : Int64;

    amunicja_pr�dko��_ustawiona, // Ustawiona pr�dko�� wystrzelenia amunicji.
    ko�o_obw�d,
    si__wiatr_si�a_aktualna__warto��_poprzednia, // Poprzednia warto�� si�y wiatru sprawdzanej przez SI.
    strza�_prze�adowanie_procent
      : double;

    lufa_pozycja_x, // Domy�lna pozycja lufy (gdy nie ma odrzutu po wystrzale).
    si__jazda_cel, // Wsp�rz�dna X punktu wskazanego jako cel jazdy przez SI.
    si__lufa_uniesienie_k�t // K�t uniesienia lufy wyznaczony przez SI.
      : single;

    si__prezent_cel_x : variant; // Je�eli SI wybra�a jako cel prezent to jest to wsp�rz�dna x prezentu, w przeciwnym wypadku ma warto�� null.

    b�otnik__lewo,
    b�otnik__prawo,
    kad�ub,
    prz�d
      : TGLCube;

    lufa,
    �wiat�o_obudowa,
    ty�
      : GLS.GeomObjects.TGLCylinder;

    �wiat�o_szybka,
    wie�a
      : TGLSphere;

    lufa_gl_dummy_cube,
    lufa_wylot_pozycja_gl_dummy_cube, // Pozycja, w kt�rej pojawia si� amunicja.
    wie�a_dummy_cube
      : TGLDummyCube;

    celownicza_linia : TGLLines;

    efekt__lufa_wystrza�_gl_fire_fx_manager,
    efekt__trafienie_gl_fire_fx_manager
      : GLS.FireFX.TGLFireFXManager;

    efekt__trafienie__alternatywny_gl_thor_fx_manager : GLS.ThorFX.TGLThorFXManager;

    ko�a_t : array [ 1..8 ] of GLS.GeomObjects.TGLCylinder;
    ko�a_�ruby_t : array [ 1..32 ] of TGLSphere; // 4 * 8 = 32.

    g�sienice_elementy_t : array [ 1..48 ] of TGLCube;
  public
    { Public declarations }
    constructor Create( AParent : TGLBaseSceneObject; gl_collision_manager_f : TGLCollisionManager; gl_cadencer_f : TGLCadencer; const efekt__lufa_wystrza�_f, efekt__trafienie_f, efekty__trafienie__alternatywny_f : boolean );
    destructor Destroy(); override;

    procedure Amunicja_Pr�dko��_Ustaw( const delta_czasu_f, wiatr__si�a_aktualna_f : double; const wysoko��_f : single; const zmniejsz_f : boolean = false );
    procedure Celownik_Wylicz( const wiatr__si�a_aktualna_f : double; const wysoko��_f : single );
    procedure Efekty__Trafienie__Utw�rz( gl_cadencer_f : TGLCadencer; const efekt__lufa_wystrza�_f, efekt__trafienie_f, efekty__trafienie__alternatywny_f : boolean );
    procedure Efekty__Trafienie__Zwolnij( const efekt__lufa_wystrza�_f, efekt__trafienie_f, efekty__trafienie__alternatywny_f : boolean );
    procedure Jed�( const delta_czasu_f : double; const do_ty�u_f : boolean = false );
    procedure Kolor_Ustaw( const vector_f : GLS.VectorTypes.TVector4f );
    procedure Lufa__Odrzut_Przesuni�cie_Ustaw();
    procedure Lufa__Uno�( const delta_czasu_f, wiatr__si�a_aktualna_f : double; const wysoko��_f : single; const w_d�_f : boolean = false );
    procedure Strza�();
  end;//---//TCzo�g

  TKrater = class( TGLDummyCube )
  private
    czy_wodny : boolean; // Czy krater powsta� na wodzie

    utworzenie_sekundy_czas_i__k : Int64; // Czas utworzenia krateru.

    lej : GLS.GeomObjects.TGLCylinder;
    dym_efekt_gl_dummy_cube : TGLDummyCube;
    grudy_t : array of GLS.GeomObjects.TGLIcosahedron;
  public
    { Public declarations }
    constructor Create( AParent : TGLBaseSceneObject; const delta_czas_f : double; const czy_woda_f : boolean = false );
    destructor Destroy(); override;
  end;//---//TKrater

  TPrezent = class( TGLDummyCube )
  private
    czy_prezent_zebrany : boolean; // Czy kto� trafi� prezent i go otrzyma�.

    trwanie_czas_sekund__p, // Ile czasu trwa prezent.
    utworzenie_sekundy_czas_i__p // Czas utworzenia prezentu.
      : Int64;

    prezent_rodzaj : TPrezent_Rodzaj;

    kszta�t,
    wst��ka_x,
    wst��ka_z
      : TGLCustomSceneObject;

    kokardka_lewo,
    kokardka_prawo
      : TGLCapsule;

    kokardka_�rodek : TGLSphere;

    efekt__zebranie_gl_fire_fx_manager : GLS.FireFX.TGLFireFXManager;
  public
    { Public declarations }
    constructor Create( AParent : TGLBaseSceneObject; cadencer_f : TGLCadencer; const efekt__zebranie_f : boolean );
    destructor Destroy(); override;

    procedure Wygl�d_Zebranie_Ustaw();
  end;//---//TPrezent

  TSosna = class( TGLDummyCube )
  private
    ko�ysanie_wychylenie_aktualne : real; // Zakres ko�ysania wyra�any w stopniach od 0 do 360 dla funkcji sinus.
    ko�ysanie_si�__dummy_cube : TGLDummyCube; // Lekko ko�ysze si� na wietrze.
    korona : GLS.GeomObjects.TGLFrustrum;
    pie� : GLS.GeomObjects.TGLCylinder;
  public
    { Public declarations }
    constructor Create( AParent : TGLBaseSceneObject );
    destructor Destroy(); override;

    procedure Ko�ysanie( const delta_czasu_f, wiatr__si�a_aktualna_f : double );
  end;//---//TSosna

  TCzolgi_Form = class( TForm )
    Gra_GLSceneViewer: TGLSceneViewer;
    Gra_GLScene: TGLScene;
    Gra_GLCamera: TGLCamera;
    Gra_GLLightSource: TGLLightSource;
    Zero_GLSphere: TGLSphere;
    Lewo_GLCube: TGLCube;
    GLCadencer1: TGLCadencer;
    GLNavigator1: TGLNavigator;
    GLUserInterface1: TGLUserInterface;
    GLCollisionManager1: TGLCollisionManager;
    PageControl1: TPageControl;
    Opcje_Splitter: TSplitter;
    Gra_TabSheet: TTabSheet;
    O_Programie_TabSheet: TTabSheet;
    O_Programie_Label: TLabel;
    Logo_Image: TImage;
    Gra_Obiekty_GLDummyCube: TGLDummyCube;
    Ziemia_GLPlane: TGLPlane;
    Woda_GLCube: TGLCube;
    Wa�_Lewo_GLCube: TGLCube;
    Wa�_Prawo_GLCube: TGLCube;
    Gracz__1__GLHUDSprite: TGLHUDSprite;
    Gracz__1__GLHUDText: TGLHUDText;
    GLWindowsBitmapFont1: TGLWindowsBitmapFont;
    Gracz__2__GLHUDSprite: TGLHUDSprite;
    Gracz__2__GLHUDText: TGLHUDText;
    Gracz__1__Czo�g_Wybrany_GroupBox: TGroupBox;
    Gracz__1__Czo�g_Wybrany__Lewo__G�ra_RadioButton: TRadioButton;
    Gracz__1__Czo�g_Wybrany__Prawo__G�ra_RadioButton: TRadioButton;
    Gracz__1__Czo�g_Wybrany__Lewo__D�_RadioButton: TRadioButton;
    Gracz__1__Czo�g_Wybrany__Prawo__D�_RadioButton: TRadioButton;
    Gracz__1__Czo�g_Wybrany__Brak_RadioButton: TRadioButton;
    Gracz__2__Czo�g_Wybrany_GroupBox: TGroupBox;
    Gracz__2__Czo�g_Wybrany__Lewo__G�ra_RadioButton: TRadioButton;
    Gracz__2__Czo�g_Wybrany__Prawo__G�ra_RadioButton: TRadioButton;
    Gracz__2__Czo�g_Wybrany__Lewo__D�_RadioButton: TRadioButton;
    Gracz__2__Czo�g_Wybrany__Prawo__D�_RadioButton: TRadioButton;
    Gracz__2__Czo�g_Wybrany__Brak_RadioButton: TRadioButton;
    Punkty__Lewo__GLHUDSprite: TGLHUDSprite;
    Punkty__Prawo__GLHUDSprite: TGLHUDSprite;
    Punkty__Lewo__GLHUDText: TGLHUDText;
    Punkty__Prawo_GLHUDText: TGLHUDText;
    Punkty__Separator_GLHUDText: TGLHUDText;
    Pauza_Button: TButton;
    Punkty_Zerowanie_BitBtn: TBitBtn;
    Efekt__Smuga_GLPerlinPFXManager: TGLPerlinPFXManager;
    GLParticleFXRenderer1: TGLParticleFXRenderer;
    Efekt__Dym_GLPerlinPFXManager: TGLPerlinPFXManager;
    Efekt__Chmury_GLPerlinPFXManager: TGLPerlinPFXManager;
    Celownicza_Linia_CheckBox: TCheckBox;
    GLSkyDome1: TGLSkyDome;
    Wiatr_Si�a_SpinEdit: TSpinEdit;
    Wiatr_Si�a_Etykieta_Label: TLabel;
    Dzie�_Noc_GLHUDSprite: TGLHUDSprite;
    Opcje_TabSheet: TTabSheet;
    Ustawienia__Wczytaj_BitBtn: TBitBtn;
    Ustawienia__Zapisz_BitBtn: TBitBtn;
    Klawiatura__Gra_GroupBox: TGroupBox;
    Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Etykieta_Label: TLabel;
    Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Etykieta_Label: TLabel;
    Klawiatura__Gra__Pauza_Etykieta_Label: TLabel;
    Klawiatura__Gra__Pe�ny_Ekran_Etykieta_Label: TLabel;
    Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Etykieta_Label: TLabel;
    Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Etykieta_Label: TLabel;
    Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Etykieta_Label: TLabel;
    Klawiatura__Gra__Wyj�cie_Etykieta_Label: TLabel;
    Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Edit: TEdit;
    Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Edit: TEdit;
    Klawiatura__Gra__Pauza_Edit: TEdit;
    Klawiatura__Gra__Pe�ny_Ekran_Edit: TEdit;
    Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Edit: TEdit;
    Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Edit: TEdit;
    Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Edit: TEdit;
    Klawiatura__Gra__Wyj�cie_Edit: TEdit;
    Klawiatura__Kamera_GroupBox: TGroupBox;
    Klawiatura__Kamera__D�_Etykieta_Label: TLabel;
    Klawiatura__Kamera__G�ra_Etykieta_Label: TLabel;
    Klawiatura__Kamera__Lewo_Etykieta_Label: TLabel;
    Klawiatura__Kamera__Przechy�_Lewo_Etykieta_Label: TLabel;
    Klawiatura__Kamera__Przechy�_Prawo_Etykieta_Label: TLabel;
    Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Etykieta_Label: TLabel;
    Klawiatura__Kamera__Prawo_Etykieta_Label: TLabel;
    Klawiatura__Kamera__Prz�d_Etykieta_Label: TLabel;
    Klawiatura__Kamera__Reset_Etykieta_Label: TLabel;
    Klawiatura__Kamera__Ty�_Etykieta_Label: TLabel;
    Klawiatura__Kamera__D�_Edit: TEdit;
    Klawiatura__Kamera__G�ra_Edit: TEdit;
    Klawiatura__Kamera__Lewo_Edit: TEdit;
    Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Edit: TEdit;
    Klawiatura__Kamera__Prawo_Edit: TEdit;
    Klawiatura__Kamera__Przechy�_Lewo_Edit: TEdit;
    Klawiatura__Kamera__Przechy�_Prawo_Edit: TEdit;
    Klawiatura__Kamera__Prz�d_Edit: TEdit;
    Klawiatura__Kamera__Reset_Edit: TEdit;
    Klawiatura__Kamera__Ty�_Edit: TEdit;
    Klawiatura__Gracz__1_GroupBox: TGroupBox;
    Klawiatura__Gracz__2_GroupBox: TGroupBox;
    Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Etykieta_Label: TLabel;
    Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Etykieta_Label: TLabel;
    Klawiatura__Gracz__1__Jed�_Lewo_Etykieta_Label: TLabel;
    Klawiatura__Gracz__1__Jed�_Prawo_Etykieta_Label: TLabel;
    Klawiatura__Gracz__1__Lufa_D�_Etykieta_Label: TLabel;
    Klawiatura__Gracz__1__Lufa_G�ra_Etykieta_Label: TLabel;
    Klawiatura__Gracz__1__Strza�_Etykieta_Label: TLabel;
    Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Edit: TEdit;
    Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Edit: TEdit;
    Klawiatura__Gracz__1__Jed�_Lewo_Edit: TEdit;
    Klawiatura__Gracz__1__Jed�_Prawo_Edit: TEdit;
    Klawiatura__Gracz__1__Lufa_D�_Edit: TEdit;
    Klawiatura__Gracz__1__Lufa_G�ra_Edit: TEdit;
    Klawiatura__Gracz__1__Strza�_Edit: TEdit;
    Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Etykieta_Label: TLabel;
    Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Etykieta_Label: TLabel;
    Klawiatura__Gracz__2__Jed�_Lewo_Etykieta_Label: TLabel;
    Klawiatura__Gracz__2__Jed�_Prawo_Etykieta_Label: TLabel;
    Klawiatura__Gracz__2__Lufa_D�_Etykieta_Label: TLabel;
    Klawiatura__Gracz__2__Lufa_G�ra_Etykieta_Label: TLabel;
    Klawiatura__Gracz__2__Strza�_Etykieta_Label: TLabel;
    Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Edit: TEdit;
    Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Edit: TEdit;
    Klawiatura__Gracz__2__Jed�_Lewo_Edit: TEdit;
    Klawiatura__Gracz__2__Jed�_Prawo_Edit: TEdit;
    Klawiatura__Gracz__2__Lufa_D�_Edit: TEdit;
    Klawiatura__Gracz__2__Lufa_G�ra_Edit: TEdit;
    Klawiatura__Gracz__2__Strza�_Edit: TEdit;
    Dzie�_Noc_CheckBox: TCheckBox;
    Dzie�_Noc__Procent_TrackBar: TTrackBar;
    Godzina_Label: TLabel;
    Ranek_Label: TLabel;
    Gra_Wsp�czynnik_Pr�dko�ci_Etykieta_Label: TLabel;
    Gra_Wsp�czynnik_Pr�dko�ci_Label: TLabel;
    Dzie�_Noc__Czas_Systemowy_Ustaw_CheckBox: TCheckBox;
    Informacja_Dodatkowa_Timer: TTimer;
    S�o�ce_Ksi�yc_GLSphere: TGLSphere;
    Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox: TCheckBox;
    Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup: TRadioGroup;
    Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup: TRadioGroup;
    Gracz__1__Akceptuje_Si_CheckBox: TCheckBox;
    Gracz__2__Akceptuje_Si_CheckBox: TCheckBox;
    Si_Linie_Bez_Graczy_CheckBox: TCheckBox;
    Klawiatura_Konfiguracja_GroupBox: TGroupBox;
    Celownicza_Linia_Wysoko��_Etykieta_Label: TLabel;
    Celownicza_Linia_Wysoko��_SpinEdit: TSpinEdit;
    Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox: TCheckBox;
    T�umaczenia_ComboBox: TComboBox;
    T�umaczenie_Etykieta_Label: TLabel;
    Chmury_GLDummyCube: TGLDummyCube;
    Chmury_GLParticleFXRenderer: TGLParticleFXRenderer;
    Trudno��_Stopie�_GroupBox: TGroupBox;
    Trudno��_Stopie�__Op�nienie__Jazda_Etykieta_Label: TLabel;
    Trudno��_Stopie�__Op�nienie__Jazda_SpinEdit: TSpinEdit;
    Trudno��_Stopie�__Op�nienie__Strza�_Etykieta_Label: TLabel;
    Trudno��_Stopie�__Op�nienie__Strza�_SpinEdit: TSpinEdit;
    Czo�gi_Linia__3_CheckBox: TCheckBox;
    Czo�gi_Linia__4_CheckBox: TCheckBox;
    Efekty_GroupBox: TGroupBox;
    Efekty__Chmury_CheckBox: TCheckBox;
    Efekty__Dym_CheckBox: TCheckBox;
    Efekty__Smuga_CheckBox: TCheckBox;
    Efekty__Prezent_Zebranie_CheckBox: TCheckBox;
    Efekty__Lufa_Wystrza�_CheckBox: TCheckBox;
    Efekty__Trafienie_CheckBox: TCheckBox;
    Efekty__Trafienie__Alternatywny_CheckBox: TCheckBox;
    procedure FormShow( Sender: TObject );
    procedure FormClose( Sender: TObject; var Action: TCloseAction );
    procedure FormResize( Sender: TObject );
    procedure GLCadencer1Progress( Sender: TObject; const deltaTime, newTime: Double );
    procedure Gra_GLSceneViewerClick( Sender: TObject );
    procedure Gra_GLSceneViewerMouseMove( Sender: TObject; Shift: TShiftState; X, Y: Integer );
    procedure Gra_GLSceneViewerKeyDown( Sender: TObject; var Key: Word; Shift: TShiftState );
    procedure GLCollisionManager1Collision( Sender: TObject; object1, object2: TGLBaseSceneObject );
    procedure PageControl1Change( Sender: TObject );
    procedure Gracz_Czo�g_Wybrany_RadioButtonClick( Sender: TObject );
    procedure Pauza_ButtonClick( Sender: TObject );
    procedure Punkty_Zerowanie_BitBtnClick( Sender: TObject );
    procedure Klawiatura_EditKeyDown( Sender: TObject; var Key: Word; Shift: TShiftState );
    procedure Ustawienia__Wczytaj_BitBtnClick( Sender: TObject );
    procedure Ustawienia__Zapisz_BitBtnClick( Sender: TObject );
    procedure Dzie�_Noc_CheckBoxClick( Sender: TObject );
    procedure Dzie�_Noc__Procent_TrackBarChange( Sender: TObject );
    procedure Informacja_Dodatkowa_TimerTimer( Sender: TObject );
    procedure Czo�gi_Linia_CheckBoxClick( Sender: TObject );
    procedure T�umaczenia_ComboBoxKeyDown( Sender: TObject; var Key: Word; Shift: TShiftState );
    procedure Efekty__Chmury_CheckBoxClick( Sender: TObject );
    procedure Efekty__Czo�gi__Utw�rz__Zwolnij_CheckBoxClick( Sender: TObject );
  private
    { Private declarations }
    noc_zapada : boolean; // Gdy true �ciemnia si�, gdy false rozja�nia si�.

    chmury_rozmie��_losowo__wyznaczenie_kolejne_sekundy_czas, // Po jakim czasie b�dzie wyliczana kolejna zmiana pozycji chmur.
    page_control_1_height_pocz�tkowe,
    prezenty__kolejne_utworzenie__za_sekundy_czas, // Po jakim czasie b�dzie dodawany kolejny prezent.
    punkty__gracz__1,
    punkty__gracz__2,
    punkty__lewo,
    punkty__prawo,
    wiatr__kolejne_wyliczenie__odliczanie_od_sekundy_czas_i, // Czas, od kt�rego odlicza� zmian� si�y wiatru.
    wiatr__kolejne_wyliczenie__za_sekundy_czas_i // Po jakim czasie b�dzie wyliczana zmiana pr�dko�ci wiatru (ustalane dopiero gry wiatr osi�gnie si�� docelow�).
      : integer;

    chmury_rozmie��_losowo__wyznaczenie_sekundy_czas_i, // Kiedy ostatnio wyliczono pozycj� chmur.
    kratery_trwanie_poprzednie_sprawdzanie_sekundy_czas_i, // Do sprawdzania czasu trwania krater�w.
    prezenty__trwanie_poprzednie_sprawdzanie_sekundy_czas_i, // Do sprawdzania czasu trwania prezent�w.
    prezenty__utworzenie_poprzednie_sprawdzanie_sekundy_czas_i // Do sprawdzania czasu pojawiania si� nowych prezent�w.
      : Int64;

    gra_wsp�czynnik_pr�dko�ci_g : currency;

    wiatr__si�a_aktualna,
    wiatr__si�a_docelowa,
    wiatr__zakres // Ustawiony zakres zmiany wiatru.
      : double;

    noc_procent : single; // 0% - jasno (12:00), 100% - ciemno (24:00).

    informacja_dodatkowa_wy�wietlenie_g, // Czas wy�wietlenia informacji dodatkowej.
    napis_od�wie�__ostatnie_wywo�anie_g
      : TDateTime;

    kamera_kopia__direction_g,
    kamera_kopia__position_g,
    kamera_kopia__up_g
      : GLS.VectorTypes.TVector4f;

    informacja_dodatkowa_g : string;

    window_state_kopia_g : TWindowState;

    amunicja_wystrzelona_list,
    kratery_list,
    prezenty_list
      : TList;

    t�umaczenie_komunikaty_r : TT�umaczenie_Komunikaty_r;

    sosna : TSosna;

    sosny_gl_proxy_object_t : array of TGLProxyObject;

    czo�gi_t : array [ 1..8 ] of TCzo�g; // Ilo�� czo�g�w (warto�� powinna by� parzysta). //???

    procedure Kamera_Ruch( const delta_czasu_f : double );
    procedure Gra_Wsp�czynnik_Pr�dko�ci_Zmie�( const zmiana_kierunek_f : smallint );
    procedure Klawisze_Obs�uga_Zachowanie_Ci�g�e( const delta_czasu_f : double );

    procedure Amunicja_Wystrzelona_Utw�rz_Jeden( czo�g_f : TCzo�g );
    procedure Amunicja_Wystrzelona_Zwolnij_Jeden( amunicja_f : TAmunicja );
    procedure Amunicja_Wystrzelona_Zwolnij_Wszystkie();
    procedure Amunicja_Ruch( const delta_czasu_f : double );

    procedure Kratery_Utw�rz_Jeden( const x_f, y_f, z_f : single; const delta_czas_f : double );
    procedure Kratery_Zwolnij_Jeden( krater_f : TKrater );
    procedure Kratery_Zwolnij_Wszystkie();
    procedure Kratery_Trwanie_Czas_Sprawd�();

    function Pauza__Sprawd�() : boolean;

    procedure Prezent_Utw�rz_Jeden();
    procedure Prezent_Zwolnij_Jeden( prezent_f : TPrezent );
    procedure Prezent_Zwolnij_Wszystkie();
    procedure Prezent_Trwanie_Czas_Sprawd�();
    procedure Prezent_Zebranie_Efekt_Animuj( const delta_czasu_f : double );

    procedure Czo�gi_Parametry_Aktualizuj();

    function Czo�g_Gracza_Indeks_Tabeli_Ustal( const czy_gracz_2_f : boolean = false ) : integer;
    procedure Interfejs_Wska�niki_Ustaw( const oczekiwanie_pomi�_f : boolean = false );

    procedure Las_Sosnowy_Utw�rz();
    procedure Wiatr_Si�a_Wylicz( const delta_czasu_f : double );
    function Wiatr_Si�a_Modyfikacja_O_Ko�ysanie() : double;
    procedure Dzie�_Noc_Zmie�( const delta_czasu_f : double );
    procedure Dzie�_Noc_Zmie�__Procent_Wed�ug_Czasu_Systemowego_Ustaw();

    function Nazwa_Klawisza( const klawisz_f : word ) : string;
    procedure Klawiatura_Konfiguracja__Niepowtarzalno��_Sprawd�();

    procedure Ustawienia_Plik( const zapisuj_ustawienia_f : boolean = false );

    function Komunikat_Wy�wietl( const text_f, caption_f : string; const flags_f : integer ) : integer;

    procedure Informacja_Dodatkowa__Ustaw( const napis_f : string = '' );
    procedure Informacja_Dodatkowa__Wa�no��_Sprawd�();

    procedure SI_Decyduj( const delta_czasu_f : double );

    procedure Chmury__Dodaj();
    procedure Chmury__Rozmie��_Losowo();
    procedure Chmury__Usu�();

    procedure T�umaczenie__Lista_Wczytaj();
    procedure T�umaczenie__Wczytaj();
    procedure T�umaczenie__Domy�lne();
    procedure T�umaczenie__Zastosuj();
  public
    { Public declarations }
  end;

var
  Czolgi_Form: TCzolgi_Form;

const
  amunicja_pr�dko��_ustawiona__maksymalna_c : double = 50;
  amunicja_pr�dko��_ustawiona__minimalna_c : double = 5;
  bonus_czo�gu_trwanie_czas_sekundy_c : Int64 = 60;
  czo�g_jazda_zakres__do_c : single = 200; //Zakres wsp�rz�dnych x do, po kt�rych mo�e je�dzi� czo�g.
  czo�g_jazda_zakres__od_c : single = 19; // Zakres wsp�rz�dnych x od, po kt�rych mo�e je�dzi� czo�g.
  efekt__trafienie__alternatywny_gl_thor_fx_manager__maxpoints__disabled_c : integer = 1; // Minimalnie 1 - aby ukry� efekt.
  efekt__trafienie__alternatywny_gl_thor_fx_manager__maxpoints__enabled_c : integer = 64;
  lufa_uniesienie_maksymalne_k�t_c : single = 85;
  si__jazda_cel__wyznaczenie_kolejne__losuj_z_sekundy_c : integer = 5;
  si__prezent_cel__wyznaczenie_kolejne_sekundy_c : Int64 = 2;
  strza�_prze�adowanie_czas_milisekundy_c : Int64 = 5000;
  prezenty__kolejne_utworzenie__losuj_z_sekundy_c : integer = 21;
  przyspieszenie_grawitacyjne_c : real = 9.81;
  wiatr__kolejne_wyliczenie__za__losuj_z_sekundy_c : integer = 30;

  function Czas_Mi�dzy_W_Sekundach( const czas_poprzedni_f : Int64; const zmienna_w_milisekundach_f : boolean = false ) : Int64;
  function Czas_Mi�dzy_W_Milisekundach( const czas_poprzedni_f : Int64; const zmienna_w_milisekundach_f : boolean = false ) : Int64;
  function Czas_Teraz() : double;
  function Czas_Teraz_W_Sekundach() : Int64;
  function Czas_Teraz_W_Milisekundach() : Int64;

  //
  // Przyk�ad u�ycia:
  //  czas_sekundy,
  //  czas_milisekundy
  //    : Int64
  //
  //  czas_sekundy := Czas_Teraz_W_Sekundach() // 1 sekunda = 1.
  //  Czas_Mi�dzy_W_Sekundach( czas_sekundy ) // 1 sekunda = 1.
  //  Czas_Mi�dzy_W_Milisekundach( czas_sekundy ) // 1 sekunda = 1 000.
  //
  //  czas_milisekundy := Czas_Teraz_W_Milisekundach() // 1 sekunda = 1 000.
  //  Czas_Mi�dzy_W_Sekundach( czas_milisekundy, true ) // 1 sekunda = 1.
  //  Czas_Mi�dzy_W_Milisekundach( czas_milisekundy, true ) // 1 sekunda = 1 000.
  //

  function Sinus( k�t_stopnie_f : single ) : real;
  function Cosinus( k�t_stopnie_f : single ) : real;
  function Tangens( k�t_stopnie_f : single ) : real; // Nieu�ywane.
  function Cotangens( k�t_stopnie_f : single ) : real; // Nieu�ywane.

  //
  // Wzory na ruch pocisku na podstawie:
  // https://www.omnicalculator.com/physics/projectile-motion
  //
  function Pocisk_Ruch__Pr�dko��_X( const pr�dko��_pocz�tkowa_f : double; const wystrza�_k�t_f : single ) : single;
  function Pocisk_Ruch__Pr�dko��_Y( const pr�dko��_pocz�tkowa_f : double; const wystrza�_k�t_f : single ) : single;
  function Pocisk_Ruch__Lot_Czas_Sekundy( const pr�dko��_pocz�tkowa_y_f, wysoko��_pocz�tkowa_f : single ) : real;
  function Pocisk_Ruch__Lot_Zasi�g_W_Poziomie( const pr�dko��_pocz�tkowa_x_f, pr�dko��_pocz�tkowa_y_f, wysoko��_pocz�tkowa_f : single; const lot_czas_sekundy_f : real; const lot_w_lewo_f : boolean; const wiatr_pr�dko��_aktualna_f : double = 0 ) : real; overload;
  function Pocisk_Ruch__Lot_Zasi�g_W_Poziomie( const pr�dko��_pocz�tkowa_x_f : single; const lot_czas_sekundy_f : real ) : real; overload;
  function Pocisk_Ruch__Lot_Wysoko��_Najwi�ksza( const pr�dko��_pocz�tkowa_y_f, wysoko��_pocz�tkowa_f : single ) : real;

implementation

uses
  GLS.Behaviours,
  GLS.Color,
  GLS.Keyboard,
  GLS.Material,

  System.DateUtils,
  System.IniFiles,
  System.Math,
  System.Rtti,
  System.StrUtils,
  System.TypInfo;

{$R *.dfm}

//      ***      Funkcje      ***      //

//Funkcja Czas_Mi�dzy_W_Sekundach().
function Czas_Mi�dzy_W_Sekundach( const czas_poprzedni_f : Int64; const zmienna_w_milisekundach_f : boolean = false ) : Int64;
begin

  //
  // Funkcja wylicza ilo�� sekund bezwzgl�dnego czasu gry jaka up�yn�a od podanego czasu do chwili obecnej.
  //
  // Zwraca ilo�� sekund bezwzgl�dnego czasu gry w postaci 123 (1:59 = 1).
  //
  // Parametry:
  //   czas_poprzedni_f - moment czasu gry, od kt�rego liczy� up�yw czasu.
  //   zmienna_w_milisekundach_f
  //     false - zmienna czas_poprzedni_f przechowuje warto�� w sekundach (warto�� zmiennej dla 1 sekunda = 1).
  //     true - zmienna czas_poprzedni_f przechowuje warto�� w milisekundach (warto�� zmiennej dla 1 sekunda = 1 000).
  //

  Result := Floor(  Czas_Mi�dzy_W_Milisekundach( czas_poprzedni_f, zmienna_w_milisekundach_f ) * 0.001  );

end;//---//Funkcja Czas_Mi�dzy_W_Sekundach().

//Funkcja Czas_Mi�dzy_W_Milisekundach().
function Czas_Mi�dzy_W_Milisekundach( const czas_poprzedni_f : Int64; const zmienna_w_milisekundach_f : boolean = false ) : Int64;
begin

  //
  // Funkcja wylicza ilo�� milisekund bezwzgl�dnego czasu gry jaka up�yn�a od podanego czasu do chwili obecnej.
  //
  // Zwraca ilo�� milisekund bezwzgl�dnego czasu gry w postaci 123 (1:30 = 1 500).
  //
  // Parametry:
  //   czas_poprzedni_f - moment czasu gry, od kt�rego liczy� up�yw czasu.
  //   zmienna_w_milisekundach_f
  //     false - zmienna czas_poprzedni_f przechowuje warto�� w sekundach (warto�� zmiennej dla 1 sekunda = 1).
  //     true - zmienna czas_poprzedni_f przechowuje warto�� w milisekundach (warto�� zmiennej dla 1 sekunda = 1 000).
  //

  if not zmienna_w_milisekundach_f then
    Result := Round(  Abs( Czolgi_Form.GLCadencer1.CurrentTime - czas_poprzedni_f ) * 1000  )
  else//if not zmienna_w_milisekundach_f then
    Result := Round(  Abs( Czolgi_Form.GLCadencer1.CurrentTime * 1000 - czas_poprzedni_f )  );

end;//---//Funkcja Czas_Mi�dzy_W_Milisekundach().

//Funkcja Czas_Teraz().
function Czas_Teraz() : double;
begin

  //
  // Funkcja zwraca aktualny bezwzgl�dny czas gry.
  //  Ze wzgl�du na pauzowanie gdy nie mo�na wylicza� na podstawie czasu systemowego.
  //
  // Zwraca aktualny bezwzgl�dny czas gry w postaci 123.456 (1:30 = 1.5).
  //

  Result := Czolgi_Form.GLCadencer1.CurrentTime;

end;//---//Funkcja Czas_Teraz().

//Funkcja Czas_Teraz_W_Sekundach().
function Czas_Teraz_W_Sekundach() : Int64;
begin

  //
  // Funkcja zwraca aktualny bezwzgl�dny czas gry bez u�amk�w sekund.
  //
  // Zwraca aktualny bezwzgl�dny czas gry bez u�amk�w sekund w postaci 123 (1:59 = 1).
  //

  Result := Floor( Czas_Teraz() );

end;//---//Funkcja Czas_Teraz_W_Sekundach().

//Funkcja Czas_Teraz_W_Milisekundach().
function Czas_Teraz_W_Milisekundach() : Int64;
begin

  //
  // Funkcja zwraca aktualny bezwzgl�dny czas gry w milisekundach.
  //
  // Zwraca aktualny bezwzgl�dny czas gry w milisekundach w postaci 123.456 (1:30 = 1 500).
  //

  Result := Round( Czolgi_Form.GLCadencer1.CurrentTime * 1000 );

end;//---//Funkcja Czas_Teraz_W_Milisekundach().

//Funkcja Sinus().
function Sinus( k�t_stopnie_f : single ) : real;
begin

  Result := Sin(  System.Math.DegToRad( k�t_stopnie_f )  );

end;//---//Funkcja Sinus().

//Funkcja Cosinus().
function Cosinus( k�t_stopnie_f : single ) : real;
begin

  Result := Cos(  System.Math.DegToRad( k�t_stopnie_f )  );

end;//---//Funkcja Cosinus().

//Funkcja Tangens().
function Tangens( k�t_stopnie_f : single ) : real;
begin

  Result := Tan(  System.Math.DegToRad( k�t_stopnie_f )  );

end;//---//Funkcja Tangens().

//Funkcja Cotangens().
function Cotangens( k�t_stopnie_f : single ) : real;
begin

  Result := Cotan(  System.Math.DegToRad( k�t_stopnie_f )  );

end;//---//Funkcja Cotangens().

//Funkcja Pocisk_Ruch__Pr�dko��_X().
function Pocisk_Ruch__Pr�dko��_X( const pr�dko��_pocz�tkowa_f : double; const wystrza�_k�t_f : single ) : single;
begin

  //
  // Funkcja wylicza pr�dko�� pocz�tkow� pocisku w osi x  [metry / sekund�].
  //
  // Zwraca pr�dko�� pocz�tkow� pocisku w osi x.
  //
  // Parametry:
  //   pr�dko��_pocz�tkowa_f - pr�dko�� z jak� wystrzelono pocisk [metry / sekund�].
  //   wystrza�_k�t_f - k�t pod jakim wystrzelono pocisk [stopnie].
  //

  Result := pr�dko��_pocz�tkowa_f * Cosinus( wystrza�_k�t_f );

end;//---//Funkcja Pocisk_Ruch__Pr�dko��_X().

//Funkcja Pocisk_Ruch__Pr�dko��_Y().
function Pocisk_Ruch__Pr�dko��_Y( const pr�dko��_pocz�tkowa_f : double; const wystrza�_k�t_f : single ) : single;
begin

  //
  // Funkcja wylicza pr�dko�� pocz�tkow� pocisku w osi y [metry / sekund�].
  //
  // Zwraca pr�dko�� pocz�tkow� pocisku w osi y.
  //
  // Parametry:
  //   pr�dko��_pocz�tkowa_f - pr�dko�� z jak� wystrzelono pocisk [metry / sekund�].
  //   wystrza�_k�t_f - k�t pod jakim wystrzelono pocisk [stopnie].
  //

  Result := pr�dko��_pocz�tkowa_f * Sinus( wystrza�_k�t_f );

end;//---//Funkcja Pocisk_Ruch__Pr�dko��_Y().

//Funkcja Pocisk_Ruch__Lot_Czas_Sekundy().
function Pocisk_Ruch__Lot_Czas_Sekundy( const pr�dko��_pocz�tkowa_y_f, wysoko��_pocz�tkowa_f : single ) : real;
begin

  //
  // Funkcja wylicza czas lotu pocisku do osi�gni�cia wysoko�ci 0 metr�w [sekundy].
  //
  // Zwraca czas lotu pocisku do osi�gni�cia wysoko�ci 0 metr�w.
  //
  // Parametry:
  //   pr�dko��_pocz�tkowa_y_f - pr�dko�� w osi y z jak� wystrzelono pocisk [metry / sekund�].
  //   wysoko��_pocz�tkowa_f - z jakiej wysoko�ci wystrzelono pocisk [metry].
  //

  Result :=
    (
        pr�dko��_pocz�tkowa_y_f
      + Sqrt
          (
              Sqr( pr�dko��_pocz�tkowa_y_f )
            +
                2
              * przyspieszenie_grawitacyjne_c
              * wysoko��_pocz�tkowa_f
          )
    )
    / przyspieszenie_grawitacyjne_c;

end;//---//Funkcja Pocisk_Ruch__Lot_Czas_Sekundy().

//Funkcja Pocisk_Ruch__Lot_Zasi�g_W_Poziomie().
function Pocisk_Ruch__Lot_Zasi�g_W_Poziomie( const pr�dko��_pocz�tkowa_x_f, pr�dko��_pocz�tkowa_y_f, wysoko��_pocz�tkowa_f : single; const lot_czas_sekundy_f : real; const lot_w_lewo_f : boolean; const wiatr_pr�dko��_aktualna_f : double = 0 ) : real;
var
  lot_kierunek : single;
begin

  //
  // Funkcja wylicza zasi�g lotu pocisku do osi�gni�cia wysoko�ci 0 metr�w [metry].
  //
  // Zwraca zasi�g lotu pocisku do osi�gni�cia wysoko�ci 0 metr�w.
  //
  // Parametry:
  //   pr�dko��_pocz�tkowa_x_f - pr�dko�� w osi x z jak� wystrzelono pocisk [metry / sekund�].
  //   pr�dko��_pocz�tkowa_y_f - pr�dko�� w osi y z jak� wystrzelono pocisk [metry / sekund�].
  //   wysoko��_pocz�tkowa_f - z jakiej wysoko�ci wystrzelono pocisk [metry].
  //   lot_czas_sekundy_f - czas lotu pocisku [sekundy].
  //   lot_w_lewo_f - false - pocisk leci z lewej strony na praw�; true - pocisk leci z prawej strony na lew�.
  //   wiatr_pr�dko��_aktualna_f - aktualna pr�dko�� wiatru [metry / sekund�].
  //

  if lot_w_lewo_f then
    lot_kierunek := -1
  else//if lot_w_lewo_f then
    lot_kierunek := 1;

  Result :=
      //pr�dko��_pocz�tkowa_x_f
      ( pr�dko��_pocz�tkowa_x_f + pr�dko��_pocz�tkowa_x_f * ( -wiatr_pr�dko��_aktualna_f * lot_kierunek ) * 0.01 )
    * Pocisk_Ruch__Lot_Czas_Sekundy( pr�dko��_pocz�tkowa_y_f, wysoko��_pocz�tkowa_f );

end;//---//Funkcja Pocisk_Ruch__Lot_Zasi�g_W_Poziomie().

//Funkcja Pocisk_Ruch__Lot_Zasi�g_W_Poziomie().
function Pocisk_Ruch__Lot_Zasi�g_W_Poziomie( const pr�dko��_pocz�tkowa_x_f : single; const lot_czas_sekundy_f : real ) : real;
begin

  //
  // Funkcja wylicza zasi�g lotu pocisku do osi�gni�cia wysoko�ci 0 metr�w [metry].
  //
  // Zwraca zasi�g lotu pocisku do osi�gni�cia wysoko�ci 0 metr�w.
  //
  // Parametry:
  //   pr�dko��_pocz�tkowa_x_f - pr�dko�� w osi x z jak� wystrzelono pocisk [metry / sekund�].
  //   lot_czas_sekundy_f - czas lotu pocisku [sekundy].
  //

  Result := pr�dko��_pocz�tkowa_x_f * lot_czas_sekundy_f;

end;//---//Funkcja Pocisk_Ruch__Lot_Zasi�g_W_Poziomie().

//Funkcja Pocisk_Ruch__Lot_Wysoko��_Najwi�ksza().
function Pocisk_Ruch__Lot_Wysoko��_Najwi�ksza( const pr�dko��_pocz�tkowa_y_f, wysoko��_pocz�tkowa_f : single ) : real;
begin

  //
  // Funkcja wylicza najwi�ksz� wysoko�� jak� osi�gnie pocisk podczas lotu [metry].
  //
  // Zwraca najwi�ksz� wysoko�� jak� osi�gnie pocisk podczas lotu.
  //
  // Parametry:
  //   pr�dko��_pocz�tkowa_y_f - pr�dko�� w osi y z jak� wystrzelono pocisk [metry / sekund�].
  //   wysoko��_pocz�tkowa_f - z jakiej wysoko�ci wystrzelono pocisk [metry].
  //

  Result := wysoko��_pocz�tkowa_f + Sqr( pr�dko��_pocz�tkowa_y_f ) / ( 2 * przyspieszenie_grawitacyjne_c );

end;//---//Funkcja Pocisk_Ruch__Lot_Wysoko��_Najwi�ksza().

//Konstruktor klasy TAmunicja.
constructor TAmunicja.Create( AParent : TGLBaseSceneObject );
begin

  inherited Create( Application );

  Self.czy_usun��_amunicja := false;
  Self.krater_utw�rz := false;
  Self.lot_w_lewo := false;

  Self.amunicja_pr�dko��_pocz�tkowa := 0;
  Self.czo�g_indeks_tabeli := -99;
  Self.lot__czas_zasi�gu_w_poziomie__milisekundy := 0.0001; // Aby nie by�o zero, potem jest dzielenie przez t� warto��.
  Self.lot__wysoko��_maksymalna := 0;
  Self.lot__zasi�g_w_poziomie := 0;
  Self.wystrza�__k�t := 0;
  Self.wystrza�_milisekundy__czas_i := 0;
  Self.wystrza�__x := 0;
  Self.wystrza�__y := 0;

  Self.Parent := AParent;

  Self.czubek := GLS.GeomObjects.TGLCone.Create( Self );
  Self.czubek.Parent := Self;
  Self.czubek.Scale.SetVector( 0.25, 1, 0.25 );
  Self.czubek.Position.X := 0.6;
  Self.czubek.RollAngle := -90;

  Self.korpus := GLS.GeomObjects.TGLCylinder.Create( Self );
  Self.korpus.Parent := Self;
  Self.korpus.Scale.SetVector( 0.25, 0.5, 0.25 );
  Self.korpus.RollAngle := 90;

end;//---//Konstruktor klasy TAmunicja.

//Destruktor klasy TAmunicja.
destructor TAmunicja.Destroy();
begin

  FreeAndNil( Self.czubek );
  FreeAndNil( Self.korpus );

  inherited;

end;//---//Destruktor klasy TAmunicja.

//Konstruktor klasy TCzo�g.
constructor TCzo�g.Create( AParent : TGLBaseSceneObject; gl_collision_manager_f : TGLCollisionManager; gl_cadencer_f : TGLCadencer; const efekt__lufa_wystrza�_f, efekt__trafienie_f, efekty__trafienie__alternatywny_f : boolean );
var
  i,
  j
    : integer;
begin

  inherited Create( Application );

  Self.amunicja_lot_w_lewo := false;
  Self.amunicja_pr�dko��_ustawiona := 23;
  Self.bonus__jazda_szybsza__zdobycie_sekundy_czas_i := 0;
  Self.bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i := 0;
  Self.efekt__lufa_wystrza�_gl_fire_fx_manager := nil;
  Self.efekt__trafienie_gl_fire_fx_manager := nil;
  Self.efekt__trafienie_sekundy_czas_i := 0;
  Self.efekt__trafienie__alternatywny_gl_thor_fx_manager := nil;
  Self.si_decyduje := false;
  Self.si__jazda_cel := 0;
  Self.si__jazda_cel__wyznaczenie_kolejne_sekundy_czas := 0;
  Self.si__jazda_cel__wyznaczenie_sekundy_czas_i := 0;
  Self.si__lufa_uniesienie_k�t := 0;
  Self.si__prezent_cel_x := null;
  Self.si__prezent_cel__wyznaczenie_sekundy_czas_i := 0;
  Self.si__wiatr_sprawdzenie_ostatnie_milisekundy_czas_i := 0;
  Self.si__wiatr_si�a_aktualna__warto��_poprzednia := 0;
  Self.strza�_poprzedni_milisekundy_czas_i := Czas_Teraz_W_Milisekundach();
  Self.strza�_prze�adowanie_procent := 0;


  Self.Parent := AParent;
  //Self.VisibleAtRunTime := true;

  Self.kad�ub := TGLCube.Create( Self );
  Self.kad�ub.Parent := Self;
  Self.kad�ub.Scale.SetVector( 3.25, 1, 2 );
  Self.kad�ub.Position.Y := 0.35;

  Self.prz�d := TGLCube.Create( Self );
  Self.prz�d.Parent := Self;
  Self.prz�d.Scale.SetVector( 0.8, 0.8, Self.kad�ub.Scale.Z );
  Self.prz�d.Position.X := Self.kad�ub.Scale.X * 0.5;
  Self.prz�d.Position.Y := Self.kad�ub.Position.Y;
  Self.prz�d.Roll( 45 );

  Self.ty� := GLS.GeomObjects.TGLCylinder.Create( Self );
  Self.ty�.Parent := Self;
  Self.ty�.Scale.SetVector( 1, Self.kad�ub.Scale.Z, Self.kad�ub.Scale.Y );
  Self.ty�.Position.X := -Self.kad�ub.Scale.X * 0.5;
  Self.ty�.Position.Y := Self.kad�ub.Position.Y;
  Self.ty�.Pitch( 90 );

  Self.b�otnik__lewo := TGLCube.Create( Self );
  Self.b�otnik__lewo.Parent := Self;
  Self.b�otnik__lewo.Scale.SetVector( 4.75, 0.01, 0.8 );
  Self.b�otnik__lewo.Position.Y := 0.75;
  Self.b�otnik__lewo.Position.Z := -1.35;

  Self.b�otnik__prawo := TGLCube.Create( Self );
  Self.b�otnik__prawo.Parent := Self;
  Self.b�otnik__prawo.Scale.SetVector( 4.75, 0.01, 0.8 );
  Self.b�otnik__prawo.Position.Y := 0.75;
  Self.b�otnik__prawo.Position.Z := 1.35;

  Self.wie�a_dummy_cube := TGLDummyCube.Create( Self );
  Self.wie�a_dummy_cube.Parent := Self;
  Self.wie�a_dummy_cube.Position.X := -1;
  Self.wie�a_dummy_cube.Position.Y := 0.85;

  Self.wie�a := TGLSphere.Create( Self );
  Self.wie�a.Parent := Self.wie�a_dummy_cube;
  Self.wie�a.Scale.SetVector( 1.8, 1.2, 1.8 );

  Self.lufa_gl_dummy_cube := TGLDummyCube.Create( Self );
  Self.lufa_gl_dummy_cube.Parent := Self.wie�a_dummy_cube;
  Self.lufa_gl_dummy_cube.Position.Y := 0.25;

  Self.lufa := GLS.GeomObjects.TGLCylinder.Create( Self );
  Self.lufa.Parent := Self.lufa_gl_dummy_cube;
  Self.lufa.Scale.SetVector( 0.3, 5, 0.3 );
  Self.lufa.Roll( 90 );
  Self.lufa.Position.X := Self.lufa.Scale.Y * 0.5;
  Self.lufa_pozycja_x := Self.lufa.Position.X;

  Self.lufa_wylot_pozycja_gl_dummy_cube := TGLDummyCube.Create( Self );
  Self.lufa_wylot_pozycja_gl_dummy_cube.Parent := Self.lufa_gl_dummy_cube;
  Self.lufa_wylot_pozycja_gl_dummy_cube.Position.X := Self.lufa.Scale.Y;

  Self.�wiat�o_obudowa := GLS.GeomObjects.TGLCylinder.Create( Self );
  Self.�wiat�o_obudowa.Parent := Self;
  Self.�wiat�o_obudowa.RollAngle := 90;
  Self.�wiat�o_obudowa.Position.X := 1.75;
  Self.�wiat�o_obudowa.Position.Y := 0.75;
  Self.�wiat�o_obudowa.Position.Z := 0.75;
  Self.�wiat�o_obudowa.Scale.Scale( 0.25 );

  Self.�wiat�o_szybka := TGLSphere.Create( Self );
  Self.�wiat�o_szybka.Parent := Self;
  Self.�wiat�o_szybka.Position.X := 1.875;
  Self.�wiat�o_szybka.Position.Y := 0.75;
  Self.�wiat�o_szybka.Position.Z := 0.75;
  Self.�wiat�o_szybka.Scale.X := 0.1;
  Self.�wiat�o_szybka.Scale.Y := 0.2;
  Self.�wiat�o_szybka.Scale.Z := 0.2;
  Self.�wiat�o_szybka.Material.FrontProperties.Emission.Color := GLS.Color.clrWhite;

  Self.celownicza_linia := TGLLines.Create( Self );
  Self.celownicza_linia.Parent := Self;
  Self.celownicza_linia.Visible := false;
  Self.celownicza_linia.Position.Z := Self.�wiat�o_obudowa.Position.Z; // Aby linie celownicze czo�g�w ustawionych naprzeciwko nie nachodzi�y na siebie.
  Self.celownicza_linia.AddNode(  Self.AbsoluteToLocal( Self.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition ).X, 0, 0  );
  Self.celownicza_linia.AddNode( 10, 0, 0 );
  Self.celownicza_linia.NodesAspect := lnaCube;


  for i := 1 to Length( Self.ko�a_�ruby_t ) do
    begin

      Self.ko�a_�ruby_t[ i ] := TGLSphere.Create( Self );
      Self.ko�a_�ruby_t[ i ].Radius := 0.1;

    end;
  //---//for i := 1 to Length( Self.ko�a_�ruby_t ) do



  for i := 1 to Length( Self.ko�a_t ) do
    begin

      Self.ko�a_t[ i ] := GLS.GeomObjects.TGLCylinder.Create( Self );
      Self.ko�a_t[ i ].Parent := Self;
      Self.ko�a_t[ i ].PitchAngle := 90;
      //Self.ko�a_t[ i ].BottomRadius := 0.5;
      Self.ko�a_t[ i ].Height := 0.5;
      Self.ko�a_t[ i ].Position.Y := 0;
      Self.ko�a_t[ i ].Position.X := -1.8;
      Self.ko�a_t[ i ].Position.Z := 1.25;

      // Nieparzyste prawo, parzyste lewo.
      if i mod 2 = 0 then
        Self.ko�a_t[ i ].Position.Z := -Self.ko�a_t[ i ].Position.Z;


      for j := 1 to 4 do
        begin

          Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + j ].Parent := Self.ko�a_t[ i ];
          Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + j ].Position.Y := -0.25;

          if i mod 2 = 0 then
            Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + j ].Position.Y := -Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + j ].Position.Y;

        end;
      //---//for j := 1 to 4 do

      Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + 1 ].Position.X := -0.25; // Ty�.
      Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + 2 ].Position.X := -Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + 1 ].Position.X; // Prz�d.
      Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + 3 ].Position.Z := 0.25; // G�ra.
      Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + 4 ].Position.Z := -Self.ko�a_�ruby_t[ ( i - 1 ) * 4 + 3 ].Position.Z; // D�.


      //Self.ko�a_t[ i ].ShowAxes := true;

    end;
  //---//for i := 1 to Length( Self.ko�a_t ) do

  Self.ko�a_t[ 3 ].Position.X := -0.6;
    Self.ko�a_t[ 4 ].Position.X := Self.ko�a_t[ 3 ].Position.X;
  Self.ko�a_t[ 5 ].Position.X := 0.6;
    Self.ko�a_t[ 6 ].Position.X := Self.ko�a_t[ 5 ].Position.X;
  Self.ko�a_t[ 7 ].Position.X := 1.8;
    Self.ko�a_t[ 8 ].Position.X := Self.ko�a_t[ 7 ].Position.X;


  Self.ko�o_obw�d := 2 * Pi() * Self.ko�a_t[ 1 ].BottomRadius;

  if Self.ko�o_obw�d <= 0 then
    Self.ko�o_obw�d := 1;

  j := 0;

  for i := 1 to Length( Self.g�sienice_elementy_t ) do
    begin

      Self.g�sienice_elementy_t[ i ] := TGLCube.Create( Self );
      Self.g�sienice_elementy_t[ i ].Parent := Self;
      Self.g�sienice_elementy_t[ i ].Scale.SetVector( 0.4, 0.1, Self.ko�a_t[ 1 ].BottomRadius + 0.2 );
      Self.g�sienice_elementy_t[ i ].Position.X := Self.ko�a_t[ 1 ].Position.X + 0.05;
      Self.g�sienice_elementy_t[ i ].Position.Z := Self.ko�a_t[ 1 ].Position.Z + 0.1; // 0.2 * 0.5.
      Self.g�sienice_elementy_t[ i ].Position.Y := -Self.ko�a_t[ 1 ].BottomRadius - Self.g�sienice_elementy_t[ i ].Scale.Y * 0.5;

      Self.g�sienice_elementy_t[ i ].Material.FrontProperties.Diffuse.Color := GLS.VectorGeometry.VectorMake( 0.2, 0.1, 0 );


      if i = 25 then // G�sienica lewa.
        j := 24;


      if i > 24 then
        Self.g�sienice_elementy_t[ i ].Position.Z := -Self.g�sienice_elementy_t[ i ].Position.Z;


      if i <= 18 + j then
        begin

          // G�ra g�sienic 9 element�w (d� 9 element�w)
          if i > 9 + j then
            Self.g�sienice_elementy_t[ i ].Position.Y := -Self.g�sienice_elementy_t[ i ].Position.Y;

          if   ( i = 10 + j ) // Pierwszy g�rny element ustawiany na pocz�tek.
            or ( i = 25 ) then // Pocz�tek g�sienicy lewej.
            Self.g�sienice_elementy_t[ i ].Position.X := Self.g�sienice_elementy_t[ 1 ].Position.X
          else//if   ( i = 10 + j ) (...)
            if i > 1 then
              Self.g�sienice_elementy_t[ i ].Position.X := Self.g�sienice_elementy_t[ i - 1 ].Position.X + Self.g�sienice_elementy_t[ i ].Scale.X + Self.g�sienice_elementy_t[ i ].Scale.X * 0.1;

        end
      else//if i <= 18 + j then
      if i <= 21 + j then
        begin

          // Ty� g�sienicy po 3 elementy.

          if i <= 24 then
            begin

              Self.g�sienice_elementy_t[ i ].Parent := Self.ko�a_t[ 1 ];
              Self.g�sienice_elementy_t[ i ].AbsolutePosition := Self.g�sienice_elementy_t[ 1 ].AbsolutePosition;

            end
          else//if i <= 24 then
            begin

              Self.g�sienice_elementy_t[ i ].Parent := Self.ko�a_t[ 2 ];
              Self.g�sienice_elementy_t[ i ].AbsolutePosition := Self.g�sienice_elementy_t[ 25 ].AbsolutePosition;

            end;
          //---//if i <= 24 then

          Self.g�sienice_elementy_t[ i ].AbsoluteUp := GLS.VectorGeometry.VectorMake( 0, 1, 0 );
          Self.g�sienice_elementy_t[ i ].AbsoluteDirection := Self.g�sienice_elementy_t[ 1 ].AbsoluteDirection;

          if i <= 24 then
            Self.ko�a_t[ 1 ].Turn( -47.5 )
          else//if i <= 24 then
            Self.ko�a_t[ 2 ].Turn( -47.5 );

        end
      else//if i <= 21 + j then
        begin

          // Prz�d g�sienicy po 3 elementy.

          if i <= 24 then
            begin

              Self.g�sienice_elementy_t[ i ].Parent := Self.ko�a_t[ 7 ];
              Self.g�sienice_elementy_t[ i ].AbsolutePosition := Self.g�sienice_elementy_t[ 18 ].AbsolutePosition;

            end
          else//if i <= 24 then
            begin

              Self.g�sienice_elementy_t[ i ].Parent := Self.ko�a_t[ 8 ];
              Self.g�sienice_elementy_t[ i ].AbsolutePosition := Self.g�sienice_elementy_t[ 42 ].AbsolutePosition;

            end;
          //---//if i <= 24 then

          Self.g�sienice_elementy_t[ i ].AbsoluteUp := GLS.VectorGeometry.VectorMake( 0, 1, 0 );
          Self.g�sienice_elementy_t[ i ].AbsoluteDirection := Self.g�sienice_elementy_t[ 1 ].AbsoluteDirection;

          if i <= 24 then
            Self.ko�a_t[ 7 ].Turn( -47.5 )
          else//if i <= 24 then
            Self.ko�a_t[ 8 ].Turn( -47.5 );

        end;
      //---//if i <= 18 + j then

    end;
  //---//for i := 1 to Length( Self.g�sienice_elementy_t ) do


  // Dynamiczne dodanie zdarzenia kolizji.
  if gl_collision_manager_f <> nil then
    with TGLBCollision.Create( Self.kad�ub.Behaviours ) do
      begin

        GroupIndex := 0;
        BoundingMode := cbmCube;
        Manager := gl_collision_manager_f;

      end;
    //---//with TGLBCollision.Create( Self.kad�ub.Behaviours ) do


  Self.Efekty__Trafienie__Utw�rz( gl_cadencer_f, efekt__lufa_wystrza�_f, efekt__trafienie_f, efekty__trafienie__alternatywny_f );

end;//---//Konstruktor klasy TCzo�g.

//Destruktor klasy TCzo�g.
destructor TCzo�g.Destroy();
var
  i : integer;
begin

  Efekty__Trafienie__Zwolnij( true, true, true );

  FreeAndNil( Self.b�otnik__lewo );
  FreeAndNil( Self.b�otnik__prawo );
  FreeAndNil( Self.kad�ub );
  FreeAndNil( Self.prz�d );
  FreeAndNil( Self.ty� );
  FreeAndNil( Self.lufa_wylot_pozycja_gl_dummy_cube );
  FreeAndNil( Self.lufa );
  FreeAndNil( Self.lufa_gl_dummy_cube );
  FreeAndNil( Self.wie�a );
  FreeAndNil( Self.wie�a_dummy_cube );
  FreeAndNil( Self.�wiat�o_obudowa );
  FreeAndNil( Self.�wiat�o_szybka );
  FreeAndNil( Self.celownicza_linia );


  // Rodzicem mo�e by� ko�o.
  for i := 1 to Length( Self.g�sienice_elementy_t ) do
    FreeAndNil( Self.g�sienice_elementy_t[ i ] );


  for i := 1 to Length( Self.ko�a_�ruby_t ) do
    FreeAndNil( Self.ko�a_�ruby_t[ i ] );

  for i := 1 to Length( Self.ko�a_t ) do
    FreeAndNil( Self.ko�a_t[ i ] );


  inherited;

end;//---//Destruktor klasy TCzo�g.

//Funkcja Amunicja_Pr�dko��_Ustaw().
procedure TCzo�g.Amunicja_Pr�dko��_Ustaw( const delta_czasu_f, wiatr__si�a_aktualna_f : double; const wysoko��_f : single; const zmniejsz_f : boolean = false );
const
  skok_c_l : double = 5;
begin

  // Ustawia pr�dko�� z jak� ma wylatywa� amunicja.

  if zmniejsz_f then
    Self.amunicja_pr�dko��_ustawiona := Self.amunicja_pr�dko��_ustawiona - skok_c_l * delta_czasu_f
  else//if zmniejsz_f then
    Self.amunicja_pr�dko��_ustawiona := Self.amunicja_pr�dko��_ustawiona + skok_c_l * delta_czasu_f;


  if Self.amunicja_pr�dko��_ustawiona < amunicja_pr�dko��_ustawiona__minimalna_c then
    Self.amunicja_pr�dko��_ustawiona := amunicja_pr�dko��_ustawiona__minimalna_c
  else//if Self.amunicja_pr�dko��_ustawiona < amunicja_pr�dko��_ustawiona__minimalna_c then
  if Self.amunicja_pr�dko��_ustawiona > amunicja_pr�dko��_ustawiona__maksymalna_c then
    Self.amunicja_pr�dko��_ustawiona := amunicja_pr�dko��_ustawiona__maksymalna_c;


  Self.Celownik_Wylicz( wiatr__si�a_aktualna_f, wysoko��_f );

end;//---//Funkcja Amunicja_Pr�dko��_Ustaw().

//Funkcja Celownik_Wylicz().
procedure TCzo�g.Celownik_Wylicz( const wiatr__si�a_aktualna_f : double; const wysoko��_f : single );
var
  //amunicja_pr�dko��_ustawiona_l,
  //lot_kierunek,
  lot__wysoko��_maksymalna_l
  //wystrza�__pr�dko��__y_l
    : single;
begin

  if    ( not Self.celownicza_linia.Visible )
    and ( not Self.si_decyduje ) then
    Exit;


  Self.celownicza_linia.Nodes[ 0 ].X := Self.AbsoluteToLocal( Self.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition ).X;


  //if Self.amunicja_lot_w_lewo then
  //  lot_kierunek := -1
  //else//if Self.amunicja_lot_w_lewo then
  //  lot_kierunek := 1;
  //
  //
  //amunicja_pr�dko��_ustawiona_l := Self.amunicja_pr�dko��_ustawiona;
  //
  //if Self.celownik__koryguj_o_si��_wiatru then
  //  amunicja_pr�dko��_ustawiona_l := amunicja_pr�dko��_ustawiona_l
  //    + Self.amunicja_pr�dko��_ustawiona * ( -wiatr__si�a_aktualna_f * lot_kierunek ) * 0.01;
  //
  //
  ////wystrza�__pr�dko��__y_l := Self.amunicja_pr�dko��_ustawiona * Sinus( Self.lufa_gl_dummy_cube.RollAngle );
  //wystrza�__pr�dko��__y_l := Pocisk_Ruch__Pr�dko��_Y( Self.amunicja_pr�dko��_ustawiona, Self.lufa_gl_dummy_cube.RollAngle );
  //
  //Self.celownicza_linia.Nodes[ 1 ].X :=
  //    Self.celownicza_linia.Nodes[ 0 ].X
  //  +
  //    //Self.amunicja_pr�dko��_ustawiona * Cosinus( Self.lufa_gl_dummy_cube.RollAngle )
  //    amunicja_pr�dko��_ustawiona_l * Cosinus( Self.lufa_gl_dummy_cube.RollAngle )
  //    //( Self.amunicja_pr�dko��_ustawiona + Self.amunicja_pr�dko��_ustawiona * ( -wiatr__si�a_aktualna_f * lot_kierunek ) * 0.01 ) * Cosinus( Self.lufa_gl_dummy_cube.RollAngle )
  //  * (
  //        wystrza�__pr�dko��__y_l
  //      + Sqrt
  //          (
  //              Sqr( wystrza�__pr�dko��__y_l )
  //            +
  //                2
  //              * przyspieszenie_grawitacyjne_c
  //              * Self.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition.Y
  //          )
  //    )
  //    / przyspieszenie_grawitacyjne_c;


  Self.celownicza_linia.Nodes[ 1 ].X :=
      Self.celownicza_linia.Nodes[ 0 ].X
    +
      Pocisk_Ruch__Lot_Zasi�g_W_Poziomie
        (
          Pocisk_Ruch__Pr�dko��_X( Self.amunicja_pr�dko��_ustawiona, Self.lufa_gl_dummy_cube.RollAngle ),
          Pocisk_Ruch__Pr�dko��_Y( Self.amunicja_pr�dko��_ustawiona, Self.lufa_gl_dummy_cube.RollAngle ),
          Self.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition.Y,
          Pocisk_Ruch__Lot_Czas_Sekundy(  Pocisk_Ruch__Pr�dko��_Y( Self.amunicja_pr�dko��_ustawiona, Self.lufa_gl_dummy_cube.RollAngle ), Self.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition.Y  ),
          Self.amunicja_lot_w_lewo,
          wiatr__si�a_aktualna_f
        );


  //lot__wysoko��_maksymalna_l := Self.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition.Y + Sqr( wystrza�__pr�dko��__y_l ) / ( 2 * przyspieszenie_grawitacyjne_c );
  //lot__wysoko��_maksymalna_l := Pocisk_Ruch__Lot_Wysoko��_Najwi�ksza( wystrza�__pr�dko��__y_l, Self.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition.Y );
  lot__wysoko��_maksymalna_l :=
    Pocisk_Ruch__Lot_Wysoko��_Najwi�ksza
      (
        Pocisk_Ruch__Pr�dko��_Y( Self.amunicja_pr�dko��_ustawiona, Self.lufa_gl_dummy_cube.RollAngle ),
        Self.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition.Y
      );

  if wysoko��_f < 0 then
    Self.celownicza_linia.Scale.Y := lot__wysoko��_maksymalna_l * 2 - Self.celownicza_linia.AbsolutePosition.Y
  else//if wysoko��_f < 0 then
    Self.celownicza_linia.Scale.Y := wysoko��_f;

end;//---//Funkcja Celownik_Wylicz().

//Funkcja Efekty__Trafienie__Utw�rz().
procedure TCzo�g.Efekty__Trafienie__Utw�rz( gl_cadencer_f : TGLCadencer; const efekt__lufa_wystrza�_f, efekt__trafienie_f, efekty__trafienie__alternatywny_f : boolean );
begin

  if    ( efekt__lufa_wystrza�_f )
    and ( Self.efekt__lufa_wystrza�_gl_fire_fx_manager = nil ) then
    begin

      Self.efekt__lufa_wystrza�_gl_fire_fx_manager := GLS.FireFX.TGLFireFXManager.Create( Self );
      Self.efekt__lufa_wystrza�_gl_fire_fx_manager.Cadencer := gl_cadencer_f;
      Self.efekt__lufa_wystrza�_gl_fire_fx_manager.Disabled := true;
      Self.efekt__lufa_wystrza�_gl_fire_fx_manager.FireDensity := 1;
      Self.efekt__lufa_wystrza�_gl_fire_fx_manager.FireRadius := 0.1;
      Self.efekt__lufa_wystrza�_gl_fire_fx_manager.ParticleSize := 0.1;

      // Dodaje efekt ognia z lufy.
      GetOrCreateFireFX( Self.lufa_wylot_pozycja_gl_dummy_cube ).Manager := Self.efekt__lufa_wystrza�_gl_fire_fx_manager;

    end;
  //---//if    ( efekt__lufa_wystrza�_f ) (...)


  if    ( efekt__trafienie_f )
    and ( Self.efekt__trafienie_gl_fire_fx_manager = nil ) then
    begin

      Self.efekt__trafienie_gl_fire_fx_manager := GLS.FireFX.TGLFireFXManager.Create( Self );
      Self.efekt__trafienie_gl_fire_fx_manager.Cadencer := gl_cadencer_f;
      Self.efekt__trafienie_gl_fire_fx_manager.Disabled := true;
      Self.efekt__trafienie_gl_fire_fx_manager.FireBurst := 0.75;
      Self.efekt__trafienie_gl_fire_fx_manager.FireCrown := 0.5;
      Self.efekt__trafienie_gl_fire_fx_manager.FireDensity := 1;
      Self.efekt__trafienie_gl_fire_fx_manager.FireDir.Y := 1;
      Self.efekt__trafienie_gl_fire_fx_manager.FireRadius := 0.25;
      Self.efekt__trafienie_gl_fire_fx_manager.MaxParticles := 2560;
      Self.efekt__trafienie_gl_fire_fx_manager.ParticleInterval := 0.025;
      Self.efekt__trafienie_gl_fire_fx_manager.ParticleLife := 20;
      Self.efekt__trafienie_gl_fire_fx_manager.ParticleSize := 0.4;
      Self.efekt__trafienie_gl_fire_fx_manager.Reference := Self;

      GetOrCreateFireFX( Self ).Manager := Self.efekt__trafienie_gl_fire_fx_manager;

    end;
  //---//if    ( efekt__trafienie_f ) (...)


  if    ( efekty__trafienie__alternatywny_f )
    and ( Self.efekt__trafienie__alternatywny_gl_thor_fx_manager = nil ) then
    begin

      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager := GLS.ThorFX.TGLThorFXManager.Create( Self );
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.Cadencer := gl_cadencer_f;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.Core := false;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.Disabled := true;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.GlowSize := 0.2;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.InnerColor.Color := GLS.Color.clrOrange;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.InnerColor.Alpha := 0.91;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.Maxpoints := efekt__trafienie__alternatywny_gl_thor_fx_manager__maxpoints__disabled_c;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.OuterColor.Color := GLS.Color.clrRed;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.OuterColor.Alpha := 0.91;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.Target.X := 2;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.Target.Y := 1;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.Target.Z := 0;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.Vibrate := 1.8;
      Self.efekt__trafienie__alternatywny_gl_thor_fx_manager.Wildness := 1.8;

      GetOrCreateThorFX( Self ).Manager := Self.efekt__trafienie__alternatywny_gl_thor_fx_manager;

    end;
  //---//if    ( efekty__trafienie__alternatywny_f ) (...)

end;//---//Funkcja Efekty__Trafienie__Utw�rz().

//Funkcja Efekty__Trafienie__Trafienie__Zwolnij().
procedure TCzo�g.Efekty__Trafienie__Zwolnij( const efekt__lufa_wystrza�_f, efekt__trafienie_f, efekty__trafienie__alternatywny_f : boolean );
begin

  if    ( efekt__lufa_wystrza�_f )
    and ( Self.efekt__lufa_wystrza�_gl_fire_fx_manager <> nil ) then
    FreeAndNil( Self.efekt__lufa_wystrza�_gl_fire_fx_manager );

  if    ( efekt__trafienie_f )
    and ( Self.efekt__trafienie_gl_fire_fx_manager <> nil ) then
    FreeAndNil( Self.efekt__trafienie_gl_fire_fx_manager );

  if    ( efekty__trafienie__alternatywny_f )
    and ( Self.efekt__trafienie__alternatywny_gl_thor_fx_manager <> nil ) then
    FreeAndNil( Self.efekt__trafienie__alternatywny_gl_thor_fx_manager );

end;//---//Funkcja Efekty__Trafienie__Zwolnij().

//Funkcja Jed�().
procedure TCzo�g.Jed�( const delta_czasu_f : double; const do_ty�u_f : boolean = false );
var
  i : integer;
  ztd : double;
  kierunek_kopia,
  g�ra_kopia,
  pozycja_kopia
    : GLS.VectorTypes.TVector4f;
begin

  // Nie mo�na wyjecha� poza pewien obszar.
  if   (
             ( Abs( Self.Position.X ) < czo�g_jazda_zakres__od_c  )
         and ( not do_ty�u_f )
       )
    or (
             ( Abs( Self.Position.X ) > czo�g_jazda_zakres__do_c  )
         and ( do_ty�u_f )
       ) then
    Exit;


  //ztd := -3 * delta_czasu_f; // Odleg�o�� jak� przejecha� czo�g.
  ztd := -3; // Odleg�o�� jak� przejecha� czo�g.


  if Self.bonus__jazda_szybsza__zdobycie_sekundy_czas_i <> 0 then
    ztd := 2 * ztd;


  if do_ty�u_f then
    ztd := -ztd;

  Self.Slide( ztd * delta_czasu_f );


  // Przy du�ych pr�dko�ciach g�sienice 'gubi�' elementy.
  if delta_czasu_f <= 0.05 then
    ztd := ztd * delta_czasu_f
  else//if delta_czasu_f <= 0.15 then
    ztd := ztd * 0.05;


  for i := 1 to Length( Self.g�sienice_elementy_t ) do
    begin

      if    ( Self.g�sienice_elementy_t[ i ].Parent = Self )
        and (
                 ( Self.g�sienice_elementy_t[ i ].Position.X < Self.ko�a_t[ 1 ].Position.X )
              or ( Self.g�sienice_elementy_t[ i ].Position.X > Self.ko�a_t[ 7 ].Position.X )
            ) then
        begin

          // Rodzicem staje si� ko�o (element g�sienicy si� obraca).

          kierunek_kopia := Self.g�sienice_elementy_t[ i ].AbsoluteDirection;
          g�ra_kopia := Self.g�sienice_elementy_t[ i ].AbsoluteUp;
          pozycja_kopia := Self.g�sienice_elementy_t[ i ].AbsolutePosition;

          //if Self.g�sienice_elementy_t[ i ].Position.X > Self.ko�a_t[ 7 ].Position.X then
          if Self.g�sienice_elementy_t[ i ].Position.X > 0 then
            Self.g�sienice_elementy_t[ i ].Parent := Self.ko�a_t[ 7 ]
          else//if Self.g�sienice_elementy_t[ i ].Position.X > 0 then
            Self.g�sienice_elementy_t[ i ].Parent := Self.ko�a_t[ 1 ];

          // Nie wiem czemu tak jest ale dzia�a.
          Self.g�sienice_elementy_t[ i ].ResetRotations();
          Self.g�sienice_elementy_t[ i ].AbsoluteUp := g�ra_kopia;
          Self.g�sienice_elementy_t[ i ].AbsoluteDirection := kierunek_kopia;
          Self.g�sienice_elementy_t[ i ].AbsolutePosition := pozycja_kopia;

        end
      else//if    ( Self.g�sienice_elementy_t[ i ].Parent = Self ) (...)
      if    ( Self.g�sienice_elementy_t[ i ].Parent <> Self )
        and (
                 (
                       ( Self.g�sienice_elementy_t[ i ].Parent.Position.X < 0 )
                   //and (   Self.AbsoluteToLocal(  Self.g�sienice_elementy_t[ i ].LocalToAbsolute( Self.g�sienice_elementy_t[ i ].Position.AsVector )  ).X > Self.ko�a_t[ 1 ].Position.X   )
                   and (  Self.AbsoluteToLocal( Self.g�sienice_elementy_t[ i ].AbsolutePosition ).X > Self.ko�a_t[ 1 ].Position.X  ) // Lepiej dzia�a.
                 )
              or (
                       ( Self.g�sienice_elementy_t[ i ].Parent.Position.X > 0 )
                   //and (   Self.AbsoluteToLocal(  Self.g�sienice_elementy_t[ i ].LocalToAbsolute( Self.g�sienice_elementy_t[ i ].Position.AsVector )  ).X < Self.ko�a_t[ 7 ].Position.X   )
                   and (  Self.AbsoluteToLocal( Self.g�sienice_elementy_t[ i ].AbsolutePosition ).X < Self.ko�a_t[ 7 ].Position.X  ) // Lepiej dzia�a.
                 )
            ) then
        begin

          // Rodzicem staje si� czo�g (element g�sienicy si� przesuwa).

          pozycja_kopia := Self.g�sienice_elementy_t[ i ].AbsolutePosition;

          Self.g�sienice_elementy_t[ i ].Parent := Self;

          Self.g�sienice_elementy_t[ i ].ResetRotations();
          Self.g�sienice_elementy_t[ i ].AbsolutePosition := pozycja_kopia;

          // Koryguje wysoko�� elementu aby nie by�a brana z pozycji na promieniu ko�a w ruchu.
          pozycja_kopia := Self.g�sienice_elementy_t[ i ].Position.AsVector;

          Self.g�sienice_elementy_t[ i ].Position.Y := -Self.ko�a_t[ 1 ].BottomRadius - Self.g�sienice_elementy_t[ i ].Scale.Y * 0.5; //???

          if pozycja_kopia.Y > Self.ko�a_t[ 1 ].Position.Y then
            Self.g�sienice_elementy_t[ i ].Position.Y := -Self.g�sienice_elementy_t[ i ].Position.Y;

        end;
      //---//if    ( Self.g�sienice_elementy_t[ i ].Parent <> Self ) (...)


      if Self.g�sienice_elementy_t[ i ].Parent = Self then
        begin

          if Self.g�sienice_elementy_t[ i ].Position.Y < Self.ko�a_t[ 1 ].Position.Y then
            Self.g�sienice_elementy_t[ i ].Slide( -ztd )
          else//if Self.g�sienice_elementy_t[ i ].Position.Y < Self.ko�a_t[ 1 ].Position.Y then
            Self.g�sienice_elementy_t[ i ].Slide( ztd );

        end;
      //---//if Self.g�sienice_elementy_t[ i ].Parent = Self then

    end;
  //---//for i := 1 to Length( Self.g�sienice_elementy_t ) do


  // Wylicza jakim procentem obwodu ko�a jest przejechany dystans i o tyle obraca ko�o.
  //ztd := 100 * ztd / Self.ko�o_obw�d; // Uproszczenie oblicze�.
  ztd := ztd / Self.ko�o_obw�d;

  for i := 1 to Length( Self.ko�a_t ) do
    //Self.ko�a_t[ i ].Turn( 360 * ztd * 0.01 ); // Uproszczenie oblicze�.
    Self.ko�a_t[ i ].Turn( 360 * ztd );

end;//---//Funkcja Jed�().

//Funkcja Kolor_Ustaw().
procedure TCzo�g.Kolor_Ustaw( const vector_f : GLS.VectorTypes.TVector4f );

  //Funkcja Kolor_Ustaw_Sk�adowe().
  procedure Kolor_Ustaw_Sk�adowe( const gl_material_f : GLS.Material.TGLMaterial );
  begin

    //gl_material_f.FrontProperties.Ambient.Color := vector_f;
    //gl_material_f.FrontProperties.Diffuse.Color := vector_f;
    gl_material_f.FrontProperties.Emission.Color := vector_f;

  end;//---//Funkcja Kolor_Ustaw_Sk�adowe().

var
  i : integer;
begin//Funkcja Kolor_Ustaw().

  Kolor_Ustaw_Sk�adowe( Self.b�otnik__lewo.Material );
  Kolor_Ustaw_Sk�adowe( Self.b�otnik__prawo.Material );
  Kolor_Ustaw_Sk�adowe( Self.kad�ub.Material );
  Kolor_Ustaw_Sk�adowe( Self.lufa.Material );
  Kolor_Ustaw_Sk�adowe( Self.prz�d.Material );
  Kolor_Ustaw_Sk�adowe( Self.�wiat�o_obudowa.Material );
  Kolor_Ustaw_Sk�adowe( Self.ty�.Material );
  Kolor_Ustaw_Sk�adowe( Self.wie�a.Material );

  for i := 1 to Length( Self.ko�a_t ) do
    Kolor_Ustaw_Sk�adowe( Self.ko�a_t[ i ].Material );

  for i := 1 to Length( Self.ko�a_�ruby_t ) do
    Kolor_Ustaw_Sk�adowe( Self.ko�a_�ruby_t[ i ].Material );


  //Self.celownicza_linia.LineColor.Color := vector_f;
  //Self.celownicza_linia.LineColor.Alpha := 1;

  // S�abo wida� kolor linii wi�c wzmacnia jadn� sk�adow�.
  if vector_f.X <> 0 then
    Self.celownicza_linia.LineColor.Color := GLS.VectorGeometry.VectorMake( 1, 0, 0, 1 )
  else
  if vector_f.Y <> 0 then
    Self.celownicza_linia.LineColor.Color := GLS.VectorGeometry.VectorMake( 0, 1, 0, 1 )
  else
  if vector_f.Z <> 0 then
    Self.celownicza_linia.LineColor.Color := GLS.VectorGeometry.VectorMake( 0, 0, 1, 1 );

end;//---//Funkcja Kolor_Ustaw().

//Funkcja Lufa__Odrzut_Przesuni�cie_Ustaw().
procedure TCzo�g.Lufa__Odrzut_Przesuni�cie_Ustaw();
begin

  //Self.lufa.Position.X := lufa_pozycja_x - 0.5 * ( 100 - Self.strza�_prze�adowanie_procent ) * 0.01;
  Self.lufa.Position.X := lufa_pozycja_x - ( 100 - Self.strza�_prze�adowanie_procent ) * 0.0055; // Uproszczenie oblicze�.

end;//---//Funkcja Lufa__Odrzut_Przesuni�cie_Ustaw().

//Funkcja Lufa__Uno�().
procedure TCzo�g.Lufa__Uno�( const delta_czasu_f, wiatr__si�a_aktualna_f : double; const wysoko��_f : single; const w_d�_f : boolean = false );
var
  ztsi : single;
begin

  ztsi := -5 * delta_czasu_f;

  if w_d�_f then
    ztsi := -ztsi;


  ztsi := Self.lufa_gl_dummy_cube.RollAngle + ztsi;

  if ztsi < 0 then
    ztsi := 0
  else//if ztsi < 0 then
  if ztsi > lufa_uniesienie_maksymalne_k�t_c then
    ztsi := lufa_uniesienie_maksymalne_k�t_c;

  Self.lufa_gl_dummy_cube.RollAngle := ztsi;


  Self.Celownik_Wylicz( wiatr__si�a_aktualna_f, wysoko��_f );

end;//---//Funkcja Lufa__Uno�().

//Funkcja Strza�().
procedure TCzo�g.Strza�();
begin

  if Self.strza�_prze�adowanie_procent < 100 then
    Exit;


  Czolgi_Form.Amunicja_Wystrzelona_Utw�rz_Jeden( Self );

  Self.strza�_prze�adowanie_procent := 0;
  Self.strza�_poprzedni_milisekundy_czas_i := Czas_Teraz_W_Milisekundach();
  Self.celownicza_linia.NodesAspect := lnaCube;

  if Self.efekt__lufa_wystrza�_gl_fire_fx_manager <> nil then
    Self.efekt__lufa_wystrza�_gl_fire_fx_manager.RingExplosion
      (
        1,
        0,
        0.1,
        GLS.VectorGeometry.AffineVectorMake( 0, 1, 1 ),
        GLS.VectorGeometry.AffineVectorMake( 0, 1, -1 ),
        Round( 1000 )
      );

end;//---//Funkcja Strza�().

//Konstruktor klasy TKrater.
constructor TKrater.Create( AParent : TGLBaseSceneObject; const delta_czas_f : double; const czy_woda_f : boolean = false );
var
  i : integer;
  zt_vector : GLS.VectorTypes.TVector4f;
begin

  inherited Create( Application );

  Self.czy_wodny := czy_woda_f;
  Self.Parent := AParent;
  Self.utworzenie_sekundy_czas_i__k := Czas_Teraz_W_Sekundach();

  Self.dym_efekt_gl_dummy_cube := TGLDummyCube.Create( Self );
  Self.dym_efekt_gl_dummy_cube.Parent := Self;
  Self.dym_efekt_gl_dummy_cube.Position.Y := 2;

  Self.lej := GLS.GeomObjects.TGLCylinder.Create( Self );
  Self.lej.Parent := Self;
  Self.lej.Scale.Y := 0.25;
  Self.lej.Scale.X := 1;
  Self.lej.Scale.Z := 1;

  if not Self.czy_wodny then
    Self.lej.Material.FrontProperties.Diffuse.Color := GLS.Color.clrCopper
  else//if not Self.czy_wodny then
    Self.lej.Material.FrontProperties.Diffuse.Color := GLS.Color.clrWhite;

  Self.lej.Material.FrontProperties.Ambient.RandomColor();

  SetLength( Self.grudy_t, 0 );
  SetLength(  Self.grudy_t, 6 + Random( 17 )  );

  zt_vector.Y := 0;

  for i := 0 to Length( Self.grudy_t ) - 1 do
    begin

      Self.grudy_t[ i ] := GLS.GeomObjects.TGLIcosahedron.Create( Self );
      Self.grudy_t[ i ].Parent := Self;
      Self.grudy_t[ i ].Material.FrontProperties.Diffuse.Color := Self.lej.Material.FrontProperties.Diffuse.Color;
      Self.grudy_t[ i ].Material.FrontProperties.Ambient.RandomColor();
      Self.grudy_t[ i ].Scale.Scale(  0.25 + Random( 6 ) * 0.1  );
      Self.grudy_t[ i ].Position.Y := Self.grudy_t[ i ].Scale.X;
      //Self.grudy_t[ i ].Turn(  Random( 381 )  );
      //Self.grudy_t[ i ].Slide( 5 );

      GLS.Behaviours.GetOrCreateInertia( Self.grudy_t[ i ] ).Mass := 1 + Self.grudy_t[ i ].Scale.X * 10;

      GLS.Behaviours.GetOrCreateInertia( Self.grudy_t[ i ] ).RotationDamping.SetDamping( 0, 1 + Self.grudy_t[ i ].Scale.X, 0.001 );
      GLS.Behaviours.GetOrCreateInertia( Self.grudy_t[ i ] ).TranslationDamping.SetDamping( 1, 1, 0.3 );

      //GLS.Behaviours.GetOrCreateInertia( Self.grudy_t[ i ] ).ApplyTorque( delta_czas_f, 0, 100000, 0 );
      //GLS.Behaviours.GetOrCreateInertia( Self.grudy_t[ i ] ).ApplyTranslationAcceleration(  delta_czas_f, VectorMake( 10000, 0, 0 )  );

      zt_vector.X := 10 + Random( 3591 );
      zt_vector.Z := 10 + Random( 3591 );

      if Random( 2 ) = 0 then
        zt_vector.X := -zt_vector.X;

      if Random( 2 ) = 0 then
        zt_vector.Z := -zt_vector.Z;

      GLS.Behaviours.GetOrCreateInertia( Self.grudy_t[ i ] ).ApplyTorque( delta_czas_f, 0, -zt_vector.X * 300, -zt_vector.Z * 300 );
      GLS.Behaviours.GetOrCreateInertia( Self.grudy_t[ i ] ).ApplyTranslationAcceleration( delta_czas_f, zt_vector );

    end;
  //---//for i := 0 to Length( Self.grudy_t ) - 1 do

end;//---//Konstruktor klasy TKrater.

//Destruktor klasy TKrater.
destructor TKrater.Destroy();
var
  i : integer;
begin

  FreeAndNil( Self.dym_efekt_gl_dummy_cube );
  FreeAndNil( Self.lej );

  for i := 0 to Length( Self.grudy_t ) - 1 do
    FreeAndNil( Self.grudy_t[ i ] );

  SetLength( Self.grudy_t, 0 );

  inherited;

end;//---//Destruktor klasy TKrater.

//Konstruktor klasy TPrezent.
constructor TPrezent.Create( AParent : TGLBaseSceneObject; cadencer_f : TGLCadencer; const efekt__zebranie_f : boolean );
begin

  inherited Create( Application );

  Self.Parent := AParent;
  Self.czy_prezent_zebrany := false;
  Self.trwanie_czas_sekund__p := 30 + Random( 31 );
  Self.utworzenie_sekundy_czas_i__p := Czas_Teraz_W_Sekundach();
  //Self.VisibleAtRunTime := true; //???

  Self.prezent_rodzaj := TPrezent_Rodzaj(Random( 2 ) + 1);

  if Random( 2 ) = 1 then
    begin

      Self.kszta�t := TGLSphere.Create( Self );

      Self.wst��ka_x := TGLSphere.Create( Self );
      Self.wst��ka_x.Scale.X := 1.1;
      Self.wst��ka_x.Scale.Y := 1.1;
      Self.wst��ka_x.Scale.Z := 0.3;

      Self.wst��ka_z := TGLSphere.Create( Self );
      Self.wst��ka_z.Scale.X := 0.3;
      Self.wst��ka_z.Scale.Y := 1.1;
      Self.wst��ka_z.Scale.Z := 1.1;

    end
  else//if Random( 2 ) = 1 then
    begin

      Self.kszta�t := TGLCube.Create( Self );

      Self.wst��ka_x := TGLCube.Create( Self );
      Self.wst��ka_x.Scale.X := 1.1;
      Self.wst��ka_x.Scale.Y := 1.1;
      Self.wst��ka_x.Scale.Z := 0.3;

      Self.wst��ka_z := TGLCube.Create( Self );
      Self.wst��ka_z.Scale.X := 0.3;
      Self.wst��ka_z.Scale.Y := 1.1;
      Self.wst��ka_z.Scale.Z := 1.1;

    end;
  //---//if Random( 2 ) = 1 then


  Self.kszta�t.Parent := Self;
  Self.kszta�t.Material.FrontProperties.Diffuse.RandomColor();

  Self.wst��ka_x.Parent := Self;
  Self.wst��ka_x.Material.FrontProperties.Diffuse.RandomColor();

  Self.wst��ka_z.Parent := Self;
  Self.wst��ka_z.Material.FrontProperties.Diffuse.Color := Self.wst��ka_x.Material.FrontProperties.Diffuse.Color;


  Self.kokardka_lewo := TGLCapsule.Create( Self );
  Self.kokardka_lewo.Parent := Self;
  Self.kokardka_lewo.Position.X := -0.2;
  Self.kokardka_lewo.Position.Y := 0.7;
  Self.kokardka_lewo.Scale.X := 0.4;
  Self.kokardka_lewo.Scale.Y := 0.4;
  Self.kokardka_lewo.Scale.Z := 0.1;
  Self.kokardka_lewo.Material.FrontProperties.Diffuse.Color := Self.wst��ka_x.Material.FrontProperties.Diffuse.Color;

  Self.kokardka_prawo := TGLCapsule.Create( Self );
  Self.kokardka_prawo.Parent := Self;
  Self.kokardka_prawo.Position.X := 0.2;
  Self.kokardka_prawo.Position.Y := 0.7;
  Self.kokardka_prawo.Scale.X := 0.4;
  Self.kokardka_prawo.Scale.Y := 0.4;
  Self.kokardka_prawo.Scale.Z := 0.1;
  Self.kokardka_prawo.Material.FrontProperties.Diffuse.Color := Self.wst��ka_x.Material.FrontProperties.Diffuse.Color;

  Self.kokardka_�rodek := TGLSphere.Create( Self );
  Self.kokardka_�rodek.Parent := Self;
  Self.kokardka_�rodek.Position.Y := 0.5;
  Self.kokardka_�rodek.Scale.Scale( 0.3 );
  Self.kokardka_�rodek.Material.FrontProperties.Diffuse.Color := Self.wst��ka_x.Material.FrontProperties.Diffuse.Color;

  Self.PitchAngle := Random( 91 ) - 45; // Wychylenie prz�d - ty�.
  Self.RollAngle := Random( 91 ) - 45; // Wychylenie lewo - prawo.
  Self.TurnAngle := Random( 361 ); // Obr�t lewo - prawo.

  if efekt__zebranie_f then
    begin

      Self.efekt__zebranie_gl_fire_fx_manager := GLS.FireFX.TGLFireFXManager.Create( Self );
      Self.efekt__zebranie_gl_fire_fx_manager.Cadencer := cadencer_f;
      Self.efekt__zebranie_gl_fire_fx_manager.Disabled := true;
      Self.efekt__zebranie_gl_fire_fx_manager.FireRadius := 0.75;
      Self.efekt__zebranie_gl_fire_fx_manager.ParticleInterval := 0.3;
      Self.efekt__zebranie_gl_fire_fx_manager.ParticleSize := 0.75;
      Self.efekt__zebranie_gl_fire_fx_manager.InnerColor.RandomColor();
      Self.efekt__zebranie_gl_fire_fx_manager.OuterColor.RandomColor();
      TGLBFireFX(Self.AddNewEffect(TGLBFireFX)).Manager := efekt__zebranie_gl_fire_fx_manager;

    end
  else//---//if efekt__zebranie_f then
    Self.efekt__zebranie_gl_fire_fx_manager := nil;

end;//---//Konstruktor klasy TPrezent.

//Destruktor klasy TPrezent.
destructor TPrezent.Destroy();
begin

  if Self.efekt__zebranie_gl_fire_fx_manager <> nil then
    FreeAndNil( Self.efekt__zebranie_gl_fire_fx_manager );

  FreeAndNil( Self.kszta�t );
  FreeAndNil( Self.wst��ka_x );
  FreeAndNil( Self.wst��ka_z );

  FreeAndNil( Self.kokardka_lewo );
  FreeAndNil( Self.kokardka_prawo );
  FreeAndNil( Self.kokardka_�rodek );

  inherited;

end;//---//Destruktor klasy TPrezent.

//Funkcja Wygl�d_Zebranie_Ustaw().
procedure TPrezent.Wygl�d_Zebranie_Ustaw();
var
  i : integer;
begin

  for i := 0 to Self.Count - 1 do
    Self.Children[ i ].Visible := false;


  Self.ResetRotations();


  if Self.efekt__zebranie_gl_fire_fx_manager <> nil then
    begin

      Self.efekt__zebranie_gl_fire_fx_manager.Disabled := false;


      Self.efekt__zebranie_gl_fire_fx_manager.IsotropicExplosion
        (
          0.5,
          0.5,
          1,
          100
        );

      Self.efekt__zebranie_gl_fire_fx_manager.RingExplosion
        (
          1,
          0,
          1,
          GLS.VectorGeometry.AffineVectorMake( 2, 0, 1 ),
          GLS.VectorGeometry.AffineVectorMake( 2, 0, 1 ),
          50
        );

    end;
  //---//if Self.efekt__zebranie_gl_fire_fx_manager <> nil then


  // Po zebraniu prezentu efekt utrzymuje si� pewien czas.
  Self.trwanie_czas_sekund__p := 5;
  Self.utworzenie_sekundy_czas_i__p := Czas_Teraz_W_Sekundach();

end;//---//Funkcja Wygl�d_Zebranie_Ustaw().

//Konstruktor klasy TSosna.
constructor TSosna.Create( AParent : TGLBaseSceneObject );
begin

  inherited Create( Application );

  Self.ko�ysanie_wychylenie_aktualne := Random( 361 );
  Self.Parent := AParent;
  Self.Position.X := -30;
  Self.Position.Z := -50;

  Self.ko�ysanie_si�__dummy_cube := TGLDummyCube.Create( Self );
  Self.ko�ysanie_si�__dummy_cube.Parent := Self;

  Self.korona := GLS.GeomObjects.TGLFrustrum.Create( Self );
  Self.korona.Parent := Self.ko�ysanie_si�__dummy_cube;
  Self.korona.Height := 1;
  Self.korona.Scale.Scale( 4 );
  Self.korona.Scale.Y := 15;
  Self.korona.Position.Y := 11.5;
  Self.korona.Material.FrontProperties.Diffuse.Color := GLS.Color.clrDkGreenCopper;

  Self.pie� := GLS.GeomObjects.TGLCylinder.Create( Self );
  Self.pie�.Parent := Self.ko�ysanie_si�__dummy_cube;
  Self.pie�.Material.FrontProperties.Emission.Color := GLS.Color.clrBrown;
  Self.pie�.Scale.Y := 5;
  Self.pie�.Position.Y := 1.75;

end;//---//Konstruktor klasy TSosna.

//Destruktor klasy TSosna.
destructor TSosna.Destroy();
begin

  FreeAndNil( Self.korona );
  FreeAndNil( Self.pie� );
  FreeAndNil( Self.ko�ysanie_si�__dummy_cube );

  inherited;

end;//---//Destruktor klasy TSosna.

//Funkcja Ko�ysanie().
procedure TSosna.Ko�ysanie( const delta_czasu_f, wiatr__si�a_aktualna_f : double );
begin

  Self.ko�ysanie_wychylenie_aktualne := Self.ko�ysanie_wychylenie_aktualne + (  25 + Random( 26 )  ) * delta_czasu_f; // Aby falowanie by�o bardziej zmienne.

  if Self.ko�ysanie_wychylenie_aktualne >= 360 then
    Self.ko�ysanie_wychylenie_aktualne := Self.ko�ysanie_wychylenie_aktualne - 360;

  Self.ko�ysanie_si�__dummy_cube.RollAngle := Sin(  DegToRad( Self.ko�ysanie_wychylenie_aktualne ) ) * 5 + wiatr__si�a_aktualna_f; // Zakres ko�ysania 5 stopni.

end;//---//Funkcja Ko�ysanie().

//Funkcja Kamera_Ruch().
procedure TCzolgi_Form.Kamera_Ruch( const delta_czasu_f : double );
const
  ruch_c_l : single = 5;
begin

  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__Prz�d_Edit.Tag ) then
    Gra_GLCamera.Move( ruch_c_l * delta_czasu_f );

  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__Ty�_Edit.Tag ) then
    Gra_GLCamera.Move( -ruch_c_l * delta_czasu_f );

  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__Lewo_Edit.Tag ) then
    Gra_GLCamera.Slide( -ruch_c_l * delta_czasu_f );

  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__Prawo_Edit.Tag ) then
    Gra_GLCamera.Slide( ruch_c_l * delta_czasu_f );


  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__G�ra_Edit.Tag ) then // G�ra.
    Gra_GLCamera.Lift( ruch_c_l * delta_czasu_f );

  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__D�_Edit.Tag ) then // D�.
    Gra_GLCamera.Lift( -ruch_c_l * delta_czasu_f );


  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__Przechy�_Lewo_Edit.Tag ) then // Beczka w lewo.
    Gra_GLCamera.Roll( ruch_c_l * delta_czasu_f * 10 );

  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__Przechy�_Prawo_Edit.Tag ) then // Beczka w prawo.
    Gra_GLCamera.Roll( -ruch_c_l * delta_czasu_f * 10 );


  //if GLS.Keyboard.IsKeyDown( 'Z' ) then
  //  Lewo_GLCube.Slide( ruch_c_l * delta_czasu_f );
  //
  //if GLS.Keyboard.IsKeyDown( 'X' ) then
  //  Lewo_GLCube.Slide( -ruch_c_l * delta_czasu_f );

end;//---//Funkcja Kamera_Ruch().

//Funkcja Gra_Wsp�czynnik_Pr�dko�ci_Zmie�().
procedure TCzolgi_Form.Gra_Wsp�czynnik_Pr�dko�ci_Zmie�( const zmiana_kierunek_f : smallint );
var
  i,
  zti
    : integer;
  ztc,
  skok
    : currency; // Nie dzia�a dla real, double, dzia�a dla currency, variant.
  zts : string;
begin

  //
  // Funkcja zmienia pr�dko�� gry.
  //
  // Parametry:
  //   zmiana_kierunek_f:
  //     -1 - spowalnia.
  //     0 - normalna pr�dko�� gry.
  //     1 - przy�piesza.
  //

  if zmiana_kierunek_f = 0 then
    gra_wsp�czynnik_pr�dko�ci_g := 1
  else//if zmiana_kierunek_f = 0 then
    begin

      // Wariant statyczny dla przedzia��w: 0.01 - 0.1 - 1
      //if   (
      //           ( gra_wsp�czynnik_pr�dko�ci_g = 0.1 )
      //       and ( zmiana_kierunek_f < 0 )
      //     )
      //  or ( gra_wsp�czynnik_pr�dko�ci_g < 0.1 ) then
      //  skok := 0.01
      //else//if   ( (...)
      //if   (
      //           ( gra_wsp�czynnik_pr�dko�ci_g = 1 )
      //       and ( zmiana_kierunek_f < 0 )
      //     )
      //  or ( gra_wsp�czynnik_pr�dko�ci_g < 1 ) then
      //  skok := 0.1
      //else//if   ( (...)
      //  skok := 1;


      // Wariant dostosowuj�cy zmian� wielko�ci skoku pr�dko�ci gry zale�nie od rz�du wielko�ci aktualnej pr�dko�ci gry (0.0001 - -900000000000000).
      if gra_wsp�czynnik_pr�dko�ci_g >= 1 then
        begin

          zts := FloatToStr(  Trunc( gra_wsp�czynnik_pr�dko�ci_g )  );
          zti := Length( zts );

          zts := '1';

          for i := 1 to zti - 1 do
            zts := zts + '0';

          skok := StrToCurr( zts );

          if    ( gra_wsp�czynnik_pr�dko�ci_g = skok )
            and ( zmiana_kierunek_f < 0 ) then
            skok := skok * 0.1
          else//if    ( gra_wsp�czynnik_pr�dko�ci_g = skok ) (...)
            skok := StrToCurr( zts );

        end
      else//if gra_wsp�czynnik_pr�dko�ci_g >= 1 then
        begin

          zts := FloatToStr(  Frac( gra_wsp�czynnik_pr�dko�ci_g )  );
          zti := Length( zts ) - 2; // 2 = '0.'.

          zts := '';

          for i := 1 to zti - 1 do
            zts := zts + '0';

          zts := '0,' + zts + '1';

          skok := StrToCurr( zts );

          if    ( gra_wsp�czynnik_pr�dko�ci_g = skok )
            and ( zmiana_kierunek_f < 0 ) then
            skok := skok * 0.1 // Po operacji 0,0001 * 0.1 zmienna currency daje wynik 0.
          else//if    ( gra_wsp�czynnik_pr�dko�ci_g = skok ) (...)
            skok := StrToCurr( zts );

        end;
      //---//if gra_wsp�czynnik_pr�dko�ci_g >= 1 then


      if zmiana_kierunek_f < 0 then
        skok := -skok;


      if zmiana_kierunek_f > 0 then
        ztc := gra_wsp�czynnik_pr�dko�ci_g;

      gra_wsp�czynnik_pr�dko�ci_g := gra_wsp�czynnik_pr�dko�ci_g + skok;

      if    ( zmiana_kierunek_f > 0 )
        and ( gra_wsp�czynnik_pr�dko�ci_g < ztc ) then // Zabezpiecza aby po osi�gni�ciu maksymalnego zakresu zmiennej jej warto�� nie przeskoczy�a na minimalny zakres zmiennej (900000000000000).
        gra_wsp�czynnik_pr�dko�ci_g := ztc;

    end;
  //---//if zmiana_kierunek_f = 0 then


  if gra_wsp�czynnik_pr�dko�ci_g <= 0 then
    gra_wsp�czynnik_pr�dko�ci_g := 0.0001;


  if not Pauza__Sprawd�() then // Je�eli zmienia si� GLCadencer1.TimeMultiplier podczas pauzy to po wy��czeniu pauzy nast�puje skok w przeliczaniu.
    GLCadencer1.TimeMultiplier := gra_wsp�czynnik_pr�dko�ci_g; // 0 - zatrzymany, (0..1) - spowalnia, 1 - pr�dko�� normalna gry, 1 > - przy�piesza.


  Gra_Wsp�czynnik_Pr�dko�ci_Label.Caption := FloatToStr( gra_wsp�czynnik_pr�dko�ci_g );


  Informacja_Dodatkowa__Ustaw( Gra_Wsp�czynnik_Pr�dko�ci_Etykieta_Label.Caption + ' ' + Gra_Wsp�czynnik_Pr�dko�ci_Label.Caption );

end;//---//Funkcja Gra_Wsp�czynnik_Pr�dko�ci_Zmie�().

//Funkcja Klawisze_Obs�uga_Zachowanie_Ci�g�e().
procedure TCzolgi_Form.Klawisze_Obs�uga_Zachowanie_Ci�g�e( const delta_czasu_f : double );
var
  zti : integer;
begin

  // Nie ma zapisu w postaci else aby mo�na by�o jednocze�nie wykonywa� kilka czynno�ci.

  zti := Czo�g_Gracza_Indeks_Tabeli_Ustal();

  if zti <> -99 then
    begin

      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__1__Strza�_Edit.Tag ) then
        czo�gi_t[ zti ].Strza�();


      if   (
                 ( zti mod 2 <> 0 )
             and (  GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__1__Jed�_Lewo_Edit.Tag )  )
           )
        or (
                 ( zti mod 2 = 0 )
             and (  GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__1__Jed�_Prawo_Edit.Tag )  )
           ) then
        czo�gi_t[ zti ].Jed�( delta_czasu_f, true );

      if   (
                 ( zti mod 2 <> 0 )
             and (  GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__1__Jed�_Prawo_Edit.Tag )  )
           )
        or (
                 ( zti mod 2 = 0 )
             and (  GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__1__Jed�_Lewo_Edit.Tag )  )
           ) then
        czo�gi_t[ zti ].Jed�( delta_czasu_f );


      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__1__Lufa_D�_Edit.Tag ) then
        czo�gi_t[ zti ].Lufa__Uno�( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value );

      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__1__Lufa_G�ra_Edit.Tag ) then
        czo�gi_t[ zti ].Lufa__Uno�( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value, true );


      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Edit.Tag ) then
        czo�gi_t[ zti ].Amunicja_Pr�dko��_Ustaw( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value, true );

      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Edit.Tag ) then
        czo�gi_t[ zti ].Amunicja_Pr�dko��_Ustaw( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value );

    end;
  //---//if zti <> -99 then


  zti := Czo�g_Gracza_Indeks_Tabeli_Ustal( true );

  if zti <> -99 then
    begin

      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__2__Strza�_Edit.Tag ) then
        czo�gi_t[ zti ].Strza�();


      if   (
                 ( zti mod 2 <> 0 )
             and (  GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__2__Jed�_Lewo_Edit.Tag )  )
           )
        or (
                 ( zti mod 2 = 0 )
             and (  GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__2__Jed�_Prawo_Edit.Tag )  )
           ) then
        czo�gi_t[ zti ].Jed�( delta_czasu_f, true );

      if   (
                 ( zti mod 2 <> 0 )
             and (  GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__2__Jed�_Prawo_Edit.Tag )  )
           )
        or (
                 ( zti mod 2 = 0 )
             and (  GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__2__Jed�_Lewo_Edit.Tag )  )
           ) then
        czo�gi_t[ zti ].Jed�( delta_czasu_f );


      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__2__Lufa_D�_Edit.Tag ) then
        czo�gi_t[ zti ].Lufa__Uno�( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value );

      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__2__Lufa_G�ra_Edit.Tag ) then
        czo�gi_t[ zti ].Lufa__Uno�( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value, true );


      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Edit.Tag ) then
        czo�gi_t[ zti ].Amunicja_Pr�dko��_Ustaw( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value, true );

      if GLS.Keyboard.IsKeyDown( Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Edit.Tag ) then
        czo�gi_t[ zti ].Amunicja_Pr�dko��_Ustaw( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value );

    end;
  //---//if zti <> -99 then

end;//---//Funkcja Klawisze_Obs�uga_Zachowanie_Ci�g�e().

//Funkcja Amunicja_Wystrzelona_Utw�rz_Jeden().
procedure TCzolgi_Form.Amunicja_Wystrzelona_Utw�rz_Jeden( czo�g_f : TCzo�g );
var
  i : integer;
  zt_amunicja : TAmunicja;
begin

  if   ( amunicja_wystrzelona_list = nil )
    or (  not Assigned( amunicja_wystrzelona_list )  )
    or ( czo�g_f = nil ) then
    Exit;


  zt_amunicja := TAmunicja.Create( Gra_Obiekty_GLDummyCube );
  amunicja_wystrzelona_list.Add( zt_amunicja );

  zt_amunicja.Position.AsVector := czo�g_f.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition;
  zt_amunicja.lot_w_lewo := czo�g_f.amunicja_lot_w_lewo;
  zt_amunicja.wystrza�__k�t := czo�g_f.lufa_gl_dummy_cube.RollAngle;
  zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t;

  //if czo�g_f.TurnAngle <> 0 then
  if zt_amunicja.lot_w_lewo then
    begin

      //zt_amunicja.lot_w_lewo := true;
      zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t;

    end;
  //---//if zt_amunicja.lot_w_lewo then


  for i := 1 to Length( czo�gi_t ) do
    if czo�gi_t[ i ] = czo�g_f then
      begin

        zt_amunicja.czo�g_indeks_tabeli := i;
        Break;

      end;
    //---//if czo�gi_t[ i ] = czo�g_f then

  zt_amunicja.amunicja_pr�dko��_pocz�tkowa := czo�g_f.amunicja_pr�dko��_ustawiona;
  //zt_amunicja.wystrza�__pr�dko��__x := zt_amunicja.amunicja_pr�dko��_pocz�tkowa * Cosinus( zt_amunicja.wystrza�__k�t );
  //zt_amunicja.wystrza�__pr�dko��__y := zt_amunicja.amunicja_pr�dko��_pocz�tkowa * Sinus( zt_amunicja.wystrza�__k�t );
  zt_amunicja.wystrza�__pr�dko��__x := Pocisk_Ruch__Pr�dko��_X( zt_amunicja.amunicja_pr�dko��_pocz�tkowa, zt_amunicja.wystrza�__k�t );
  zt_amunicja.wystrza�__pr�dko��__y := Pocisk_Ruch__Pr�dko��_Y( zt_amunicja.amunicja_pr�dko��_pocz�tkowa, zt_amunicja.wystrza�__k�t );
  zt_amunicja.wystrza�__x := czo�g_f.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition.X;
  zt_amunicja.wystrza�__y := czo�g_f.lufa_wylot_pozycja_gl_dummy_cube.AbsolutePosition.Y;

  //// Warto�� wyliczona tutaj jest w sekundach (123,456).
  //zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy :=
  //  (
  //      zt_amunicja.wystrza�__pr�dko��__y
  //    + Sqrt
  //        (
  //            Sqr( zt_amunicja.wystrza�__pr�dko��__y )
  //          +
  //              2
  //            * przyspieszenie_grawitacyjne_c
  //            * zt_amunicja.wystrza�__y
  //        )
  //  )
  //  / przyspieszenie_grawitacyjne_c;

  // Warto�� wyliczona tutaj jest w sekundach (123,456).
  zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy := Pocisk_Ruch__Lot_Czas_Sekundy( zt_amunicja.wystrza�__pr�dko��__y, zt_amunicja.wystrza�__y );

  //zt_amunicja.lot__wysoko��_maksymalna := zt_amunicja.wystrza�__y + Sqr( zt_amunicja.wystrza�__pr�dko��__y ) / ( 2 * przyspieszenie_grawitacyjne_c );
  //zt_amunicja.lot__zasi�g_w_poziomie := zt_amunicja.wystrza�__pr�dko��__x * zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy;

  zt_amunicja.lot__wysoko��_maksymalna := Pocisk_Ruch__Lot_Wysoko��_Najwi�ksza( zt_amunicja.wystrza�__pr�dko��__y, zt_amunicja.wystrza�__y );
  zt_amunicja.lot__zasi�g_w_poziomie := Pocisk_Ruch__Lot_Zasi�g_W_Poziomie( zt_amunicja.wystrza�__pr�dko��__x, zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy );


  if zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy <= 0 then
    zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy := 0.0001; // Aby nie by�o zero, potem jest dzielenie przez t� warto��.

  // Przeliczenie na milisekundy.
  zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy := zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy * 1000; // Warto�� w milisekundach (gry).


  // Dynamiczne dodanie zdarzenia kolizji.
  with TGLBCollision.Create( zt_amunicja.korpus.Behaviours ) do
    begin

      GroupIndex := 0;
      BoundingMode := cbmCube;
      Manager := GLCollisionManager1;

    end;
  //---//with TGLBCollision.Create( zt_amunicja.kad�ub.Behaviours ) do

  // Dodaje efekt smugi za amunicj�.
  if Efekty__Smuga_CheckBox.Checked then
    with GLS.ParticleFX.GetOrCreateSourcePFX( zt_amunicja.korpus ) do
      begin

        Manager := Efekt__Smuga_GLPerlinPFXManager;
        ParticleInterval := 0.01;
        //MoveUp();

      end;
    //---//with GLS.ParticleFX.GetOrCreateSourcePFX( zt_amunicja.korpus ) do


  zt_amunicja.wystrza�_milisekundy__czas_i := Czas_Teraz_W_Milisekundach();

end;//---//Funkcja Amunicja_Wystrzelona_Utw�rz_Jeden().

//Funkcja Amunicja_Wystrzelona_Zwolnij_Jeden().
procedure TCzolgi_Form.Amunicja_Wystrzelona_Zwolnij_Jeden( amunicja_f : TAmunicja );
begin

  if   ( amunicja_wystrzelona_list = nil )
    or (  not Assigned( amunicja_wystrzelona_list )  )
    or ( amunicja_f = nil ) then
    Exit;

  amunicja_wystrzelona_list.Remove( amunicja_f );
  FreeAndNil( amunicja_f );

end;//---//Funkcja Amunicja_Wystrzelona_Zwolnij_Jeden().

//Funkcja Amunicja_Wystrzelona_Zwolnij_Wszystkie().
procedure TCzolgi_Form.Amunicja_Wystrzelona_Zwolnij_Wszystkie();
var
  i : integer;
begin

  if   ( amunicja_wystrzelona_list = nil )
    or (  not Assigned( amunicja_wystrzelona_list )  ) then
    Exit;


  for i := amunicja_wystrzelona_list.Count - 1 downto 0 do
    begin

      TAmunicja(amunicja_wystrzelona_list[ i ]).Free();
      amunicja_wystrzelona_list.Delete( i );

    end;
  //---//for i := amunicja_wystrzelona_list.Count - 1 downto 0 do

end;//---//Funkcja Amunicja_Wystrzelona_Zwolnij_Wszystkie().

//Funkcja Amunicja_Ruch().
procedure TCzolgi_Form.Amunicja_Ruch( const delta_czasu_f : double );
var
  i : integer;
  czas_up�yn��_sekundy, // Ile czasu lotu ju� min�o (warto�� w sekundach z u�amkami w postaci 123,456 aby zachowa� zgodno�� jednostek u�ywanych we wzorach) [sekundy].
  czas_up�yn��_procent // Jaki procent zak�adanego czasu lotu up�yn��.
    : real;
  lot_kierunek
  //x_przebyte_l // Taka ciekawostka i do sprawdzania oblicze�.
    : single;
  zt_amunicja : TAmunicja;
begin

  if   ( amunicja_wystrzelona_list = nil )
    or (  not Assigned( amunicja_wystrzelona_list )  ) then
    Exit;

  for i := amunicja_wystrzelona_list.Count - 1 downto 0 do
    begin

      zt_amunicja := TAmunicja(amunicja_wystrzelona_list[ i ]);

      if zt_amunicja <> nil then
        begin

          if    ( not zt_amunicja.czy_usun��_amunicja )
            and ( zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy <> 0 )
            and ( zt_amunicja.AbsolutePosition.Y > -1 ) then
            begin

              if zt_amunicja.lot_w_lewo then
                lot_kierunek := -1
              else//if zt_amunicja.lot_w_lewo then
                lot_kierunek := 1;


              czas_up�yn��_sekundy := Czas_Mi�dzy_W_Milisekundach( zt_amunicja.wystrza�_milisekundy__czas_i, true ) / 1000;

              // Wariant bez modyfikowania o si�� wiatru.
              //zt_amunicja.Position.X :=
              //    zt_amunicja.wystrza�__x
              //  +
              //      lot_kierunek
              //    * zt_amunicja.wystrza�__pr�dko��__x
              //    * czas_up�yn��_sekundy;

              // Zasi�g amunicji zmieniany przez si�� wiatru.
              // Przy tych wzorach naj�atwiej chyba wp�ywa� si�� wiatru na pr�dko�� w osi x.
              //
              // Wzory na aktualn� warto�� x i y na podstawie:
              // https://blog.myrank.co.in/projectile-motion-2/
              //
              zt_amunicja.Position.X :=
                  zt_amunicja.wystrza�__x
                +
                    lot_kierunek
                  * (  zt_amunicja.wystrza�__pr�dko��__x + zt_amunicja.wystrza�__pr�dko��__x * ( -Wiatr_Si�a_Modyfikacja_O_Ko�ysanie() ) * lot_kierunek * 0.01  )
                  * czas_up�yn��_sekundy;

              zt_amunicja.Position.Y :=
                  zt_amunicja.wystrza�__y
                + (
                        zt_amunicja.wystrza�__pr�dko��__y
                      * czas_up�yn��_sekundy
                    -
                        przyspieszenie_grawitacyjne_c
                      * Sqr( czas_up�yn��_sekundy )
                      * 0.5
                  );


              // Zmienia pochylenie amunicji.
              czas_up�yn��_procent := 100 * Czas_Mi�dzy_W_Milisekundach( zt_amunicja.wystrza�_milisekundy__czas_i, true ) / zt_amunicja.lot__czas_zasi�gu_w_poziomie__milisekundy;

              // Czubek amunicji obni�a si� o dwukrotno�� k�ta wystrzelenia amunicji r�wnomiernie podczas ca�ego lotu.
              if not zt_amunicja.lot_w_lewo then
                zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t - 2 * lot_kierunek * zt_amunicja.wystrza�__k�t * czas_up�yn��_procent * 0.01
              else//if not zt_amunicja.lot_w_lewo then
                zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t - 2 * lot_kierunek * zt_amunicja.wystrza�__k�t * czas_up�yn��_procent * 0.01;


              {$region 'Alternatywne warianty pochylania amunicji.'}
              //// W drugiej po�owie lotu czubek amunicji obni�a si� o dwukrotno�� k�ta wystrzelenia amunicji.
              //if    ( czas_up�yn��_procent >= 50 )
              //  and ( czas_up�yn��_procent <= 100 ) then
              //  if not zt_amunicja.lot_w_lewo then
              //    begin
              //
              //      //zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t - 2 * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 2 * 0.01;
              //      zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t - lot_kierunek * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 0.04; // Uproszczenie oblicze�.
              //
              //    end
              //  else//if not zt_amunicja.lot_w_lewo then
              //    begin
              //
              //      //zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t + 2 * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 2 * 0.01;
              //      zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t - lot_kierunek * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 0.04; // Uproszczenie oblicze�.
              //
              //    end;
              //  //---//if not zt_amunicja.lot_w_lewo then
              //
              //
              //// Czubek amunicji obni�a si� o dwukrotno�� k�ta wystrzelenia amunicji w cz�ci lotu od 25% do 75%.
              //if    ( czas_up�yn��_procent >= 25 )
              //  and ( czas_up�yn��_procent <= 75 ) then
              //  if not zt_amunicja.lot_w_lewo then
              //    begin
              //
              //      zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t - 2 * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 25 ) * 2 * 0.01;
              //      //zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t - lot_kierunek * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 0.04; // Uproszczenie oblicze�.
              //
              //    end
              //  else//if not zt_amunicja.lot_w_lewo then
              //    begin
              //
              //      zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t + 2 * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 25 ) * 2 * 0.01;
              //      //zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t - lot_kierunek * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 0.04; // Uproszczenie oblicze�.
              //
              //    end;
              //  //---//if not zt_amunicja.lot_w_lewo then
              //
              //// Czubek amunicji obni�a si� o dwukrotno�� k�ta wystrzelenia amunicji w cz�ci lotu od 10% do 90%.
              //if    ( czas_up�yn��_procent >= 10 )
              //  and ( czas_up�yn��_procent <= 90 ) then
              //  if not zt_amunicja.lot_w_lewo then
              //    begin
              //
              //      zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t - 2 * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 10 ) * ( 100 / 80 ) * 0.01; // 90% - 10 = 80
              //      //zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t - lot_kierunek * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 0.04; // Uproszczenie oblicze�.
              //
              //    end
              //  else//if not zt_amunicja.lot_w_lewo then
              //    begin
              //
              //      zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t + 2 * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 10 ) * ( 100 / 80 ) * 0.01;
              //      //zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t - lot_kierunek * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 0.04; // Uproszczenie oblicze�.
              //
              //    end;
              //  //---//if not zt_amunicja.lot_w_lewo then
              //
              //
              //// Czubek amunicji obni�a si� o dwukrotno�� k�ta wystrzelenia amunicji w cz�ci lotu do 90%.
              //if czas_up�yn��_procent <= 90 then
              //  if not zt_amunicja.lot_w_lewo then
              //    begin
              //
              //      zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t - 2 * zt_amunicja.wystrza�__k�t * czas_up�yn��_procent * ( 100 / 90 ) * 0.01; // Przy 80% ma by� obr�t o 100%.
              //      //zt_amunicja.RollAngle := zt_amunicja.wystrza�__k�t - lot_kierunek * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 0.04; // Uproszczenie oblicze�.
              //
              //    end
              //  else//if not zt_amunicja.lot_w_lewo then
              //    begin
              //
              //      zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t + 2 * zt_amunicja.wystrza�__k�t * czas_up�yn��_procent * ( 100 / 80 ) * 0.01;
              //      //zt_amunicja.RollAngle := 180 - zt_amunicja.wystrza�__k�t - lot_kierunek * zt_amunicja.wystrza�__k�t * ( czas_up�yn��_procent - 50 ) * 0.04; // Uproszczenie oblicze�.
              //
              //    end;
              //  //---//if not zt_amunicja.lot_w_lewo then
              {$endregion 'Alternatywne warianty pochylania amunicji.'}


              //x_przebyte_l := Abs( zt_amunicja.wystrza�__x - zt_amunicja.Position.X );
              //
              //// Najwy�sza osi�gni�ta wysoko�� (taka ciekawostka i do sprawdzania oblicze�).
              //if zt_amunicja.TagFloat < zt_amunicja.Position.Y then
              //  zt_amunicja.TagFloat := zt_amunicja.Position.Y;

            end
          else//if    ( not zt_amunicja.czy_usun��_amunicja ) (...)
            begin

              if   ( not zt_amunicja.czy_usun��_amunicja )
                or ( zt_amunicja.krater_utw�rz ) then
                Kratery_Utw�rz_Jeden( zt_amunicja.AbsolutePosition.X, 0, zt_amunicja.AbsolutePosition.Z, delta_czasu_f );

              Amunicja_Wystrzelona_Zwolnij_Jeden( zt_amunicja );

            end;
          //---//if    ( not zt_amunicja.czy_usun��_amunicja ) (...)

        end;
      //---//if zt_amunicja <> nil then

    end;
  //---//for i := amunicja_wystrzelona_list.Count - 1 downto 0 do

end;//---//Funkcja Amunicja_Ruch().

//Funkcja Kratery_Utw�rz_Jeden().
procedure TCzolgi_Form.Kratery_Utw�rz_Jeden( const x_f, y_f, z_f : single; const delta_czas_f : double );
var
  zt_krater : TKrater;
begin

  if   ( kratery_list = nil )
    or (  not Assigned( kratery_list )  ) then
    Exit;


  zt_krater := TKrater.Create(  Gra_Obiekty_GLDummyCube, delta_czas_f, Abs( x_f ) <= Woda_GLCube.Scale.X * 0.5  );
  kratery_list.Add( zt_krater );

  zt_krater.Position.SetPoint( x_f, y_f, z_f );

  // Dodaje efekt dymu nad kraterem.
  if    ( not zt_krater.czy_wodny )
    and ( Efekty__Dym_CheckBox.Checked ) then
    with GLS.ParticleFX.GetOrCreateSourcePFX( zt_krater.dym_efekt_gl_dummy_cube ) do
      begin

        Manager := Efekt__Dym_GLPerlinPFXManager;
        ParticleInterval := 0.01;

      end;
    //---//with GLS.ParticleFX.GetOrCreateSourcePFX( zt_krater.dym_efekt_gl_dummy_cube ) do

end;//---//Funkcja Kratery_Utw�rz_Jeden().

//Funkcja Kratery_Zwolnij_Jeden().
procedure TCzolgi_Form.Kratery_Zwolnij_Jeden( krater_f : TKrater );
begin

  if   ( kratery_list = nil )
    or (  not Assigned( kratery_list )  )
    or ( krater_f = nil ) then
    Exit;

  kratery_list.Remove( krater_f );
  FreeAndNil( krater_f );

end;//---//Funkcja Kratery_Zwolnij_Jeden().

//Funkcja Kratery_Zwolnij_Wszystkie().
procedure TCzolgi_Form.Kratery_Zwolnij_Wszystkie();
var
  i : integer;
begin

  if   ( kratery_list = nil )
    or (  not Assigned( kratery_list )  ) then
    Exit;


  for i := kratery_list.Count - 1 downto 0 do
    begin

      TKrater(kratery_list[ i ]).Free();
      kratery_list.Delete( i );

    end;
  //---//for i := kratery_list.Count - 1 downto 0 do

end;//---//Funkcja Kratery_Zwolnij_Wszystkie().

//Funkcja Kratery_Trwanie_Czas_Sprawd�().
procedure TCzolgi_Form.Kratery_Trwanie_Czas_Sprawd�();
var
  i : integer;
begin

  if   ( kratery_list = nil )
    or (  not Assigned( kratery_list )  )
    or (  Czas_Mi�dzy_W_Sekundach( kratery_trwanie_poprzednie_sprawdzanie_sekundy_czas_i ) < 2  ) then
    Exit;


  for i := kratery_list.Count - 1 downto 0 do
    begin

      if    ( TKrater(kratery_list[ i ]).dym_efekt_gl_dummy_cube.Effects.Count > 0 )
        and (  Czas_Mi�dzy_W_Sekundach( TKrater(kratery_list[ i ]).utworzenie_sekundy_czas_i__k ) > 6  ) then
        TKrater(kratery_list[ i ]).dym_efekt_gl_dummy_cube.Effects.Clear();

      if   (
                 ( TKrater(kratery_list[ i ]).czy_wodny )
             and (  Czas_Mi�dzy_W_Sekundach( TKrater(kratery_list[ i ]).utworzenie_sekundy_czas_i__k ) > 2  )
           )
        or (
                 ( not TKrater(kratery_list[ i ]).czy_wodny )
             and (  Czas_Mi�dzy_W_Sekundach( TKrater(kratery_list[ i ]).utworzenie_sekundy_czas_i__k ) > 60  )
           ) then
        begin

          Kratery_Zwolnij_Jeden( TKrater(kratery_list[ i ]) );

        end;
      //---//if   ( (...)

    end;
  //---//for i := kratery_list.Count - 1 downto 0 do

  kratery_trwanie_poprzednie_sprawdzanie_sekundy_czas_i := Czas_Teraz_W_Sekundach();

end;//---//Funkcja Kratery_Trwanie_Czas_Sprawd�().

//Funkcja Pauza__Sprawd�().
function TCzolgi_Form.Pauza__Sprawd�() : boolean;
begin

  //
  // Funkcja sprawdza czy jest aktywna pauza.
  //
  // Zwraca prawd� gdy jest aktywna pauza.
  //

  Result := not GLCadencer1.Enabled;

end;//---//Funkcja Pauza__Sprawd�().

//Funkcja Prezent_Utw�rz_Jeden().
procedure TCzolgi_Form.Prezent_Utw�rz_Jeden();

  //Funkcja Prezent_Utw�rz() w Prezent_Utw�rz_Jeden().
  procedure Prezent_Utw�rz( const z_f : single );
  var
    x : single;
    zt_prezent : TPrezent;
  begin

    zt_prezent := TPrezent.Create( Gra_Obiekty_GLDummyCube, GLCadencer1, Efekty__Prezent_Zebranie_CheckBox.Checked );
    prezenty_list.Add( zt_prezent );

    x := Random( 21 ) - 10;

    zt_prezent.Position.SetPoint(  x, 0.5 + Random( 11 ) * 0.1, z_f  );


    // Dynamiczne dodanie zdarzenia kolizji.
    with TGLBCollision.Create( zt_prezent.kszta�t.Behaviours ) do
      begin

        GroupIndex := 0;

        if zt_prezent.kszta�t is TGLSphere then
          BoundingMode := cbmSphere
        else//if zt_prezent.kszta�t is TGLSphere then
          BoundingMode := cbmCube;

        Manager := GLCollisionManager1;

      end;
    //---//with TGLBCollision.Create( zt_prezent.kszta�t.Behaviours ) do

  end;//---//Funkcja Prezent_Utw�rz() w Prezent_Utw�rz_Jeden().

const
  prezent_szansa_c_l : integer = 2;
begin//Funkcja Prezent_Utw�rz_Jeden().

  if   ( prezenty_list = nil )
    or (  not Assigned( prezenty_list )  )
    or (  Czas_Mi�dzy_W_Sekundach( prezenty__utworzenie_poprzednie_sprawdzanie_sekundy_czas_i ) <= prezenty__kolejne_utworzenie__za_sekundy_czas  ) then
    Exit;


  // Dla ka�dej linii czo�g�w osobno losuje dodanie prezent�w.


  if    (  Length( czo�gi_t ) >= 1  )
    and (  Random( prezent_szansa_c_l ) = 0  ) then
    Prezent_Utw�rz( czo�gi_t[ 1 ].Position.Z );

  if    (  Length( czo�gi_t ) >= 3  )
    and (  Random( prezent_szansa_c_l ) = 0  ) then
    Prezent_Utw�rz( czo�gi_t[ 3 ].Position.Z );

  if    ( Czo�gi_Linia__3_CheckBox.Checked )
    and (  Length( czo�gi_t ) >= 5  )
    and (  Random( prezent_szansa_c_l ) = 0  ) then
    Prezent_Utw�rz( czo�gi_t[ 5 ].Position.Z );

  if    ( Czo�gi_Linia__4_CheckBox.Checked )
    and (  Length( czo�gi_t ) >= 7  )
    and (  Random( prezent_szansa_c_l ) = 0  ) then
    Prezent_Utw�rz( czo�gi_t[ 7 ].Position.Z );


  prezenty__kolejne_utworzenie__za_sekundy_czas := 10 + Random( prezenty__kolejne_utworzenie__losuj_z_sekundy_c );
  prezenty__utworzenie_poprzednie_sprawdzanie_sekundy_czas_i := Czas_Teraz_W_Sekundach();

end;//---//Funkcja Prezent_Utw�rz_Jeden().

//Funkcja Prezent_Zwolnij_Jeden().
procedure TCzolgi_Form.Prezent_Zwolnij_Jeden( prezent_f : TPrezent );
begin

  if   ( prezenty_list = nil )
    or (  not Assigned( prezenty_list )  )
    or ( prezent_f = nil ) then
    Exit;

  prezenty_list.Remove( prezent_f );
  FreeAndNil( prezent_f );

end;//---//Funkcja Prezent_Zwolnij_Jeden().

//Funkcja Prezent_Zwolnij_Wszystkie().
procedure TCzolgi_Form.Prezent_Zwolnij_Wszystkie();
var
  i : integer;
begin

  if   ( prezenty_list = nil )
    or (  not Assigned( prezenty_list )  ) then
    Exit;


  for i := prezenty_list.Count - 1 downto 0 do
    begin

      TPrezent(prezenty_list[ i ]).Free();
      prezenty_list.Delete( i );

    end;
  //---//for i := prezenty_list.Count - 1 downto 0 do

end;//---//Funkcja Prezent_Zwolnij_Wszystkie().

//Funkcja Prezent_Trwanie_Czas_Sprawd�().
procedure TCzolgi_Form.Prezent_Trwanie_Czas_Sprawd�();
var
  i : integer;
begin

  if   ( prezenty_list = nil )
    or (  not Assigned( prezenty_list )  )
    or (  Czas_Mi�dzy_W_Sekundach( prezenty__trwanie_poprzednie_sprawdzanie_sekundy_czas_i ) < 2  ) then
    Exit;


  for i := prezenty_list.Count - 1 downto 0 do
    begin

      if Czas_Mi�dzy_W_Sekundach( TPrezent(prezenty_list[ i ]).utworzenie_sekundy_czas_i__p ) > TPrezent(prezenty_list[ i ]).trwanie_czas_sekund__p then
        begin

          Prezent_Zwolnij_Jeden( TPrezent(prezenty_list[ i ]) );

        end;
      //---//if Czas_Mi�dzy_W_Sekundach( TPrezent(prezenty_list[ i ]).utworzenie_sekundy_czas_i__p ) > TPrezent(prezenty_list[ i ]).trwanie_czas_sekund__p then

    end;
  //---//for i := prezenty_list.Count - 1 downto 0 do

  prezenty__trwanie_poprzednie_sprawdzanie_sekundy_czas_i := Czas_Teraz_W_Sekundach();

end;//---//Funkcja Prezent_Trwanie_Czas_Sprawd�().

//Funkcja Prezent_Zebranie_Efekt_Animuj().
procedure TCzolgi_Form.Prezent_Zebranie_Efekt_Animuj( const delta_czasu_f : double );
var
  i : integer;
begin

  if   ( prezenty_list = nil )
    or (  not Assigned( prezenty_list )  ) then
    Exit;


  for i := prezenty_list.Count - 1 downto 0 do
    begin

      if TPrezent(prezenty_list[ i ]).czy_prezent_zebrany then
        TPrezent(prezenty_list[ i ]).Lift( 1 * delta_czasu_f );

    end;
  //---//for i := prezenty_list.Count - 1 downto 0 do

end;//---//Funkcja Prezent_Zebranie_Efekt_Animuj().

//Funkcja Czo�gi_Parametry_Aktualizuj().
procedure TCzolgi_Form.Czo�gi_Parametry_Aktualizuj();
var
  i : integer;
begin

  for i := 1 to Length( czo�gi_t ) do
    if czo�gi_t[ i ] <> nil then
      begin

        if czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager <> nil then
          begin

            if not czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager.Disabled then
              czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager.InitialDir.X := -Wiatr_Si�a_Modyfikacja_O_Ko�ysanie() * 0.1;

            if    ( not czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager.Disabled )
              and (  Czas_Mi�dzy_W_Sekundach( czo�gi_t[ i ].efekt__trafienie_sekundy_czas_i ) > 6  ) then
              czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager.Disabled := true;

          end;
        //---//if czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager <> nil then


        if czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager <> nil then
          begin

            if    ( not czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager.Disabled )
              and (  Czas_Mi�dzy_W_Sekundach( czo�gi_t[ i ].efekt__trafienie_sekundy_czas_i ) > 6  ) then
              begin

                czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager.Maxpoints := efekt__trafienie__alternatywny_gl_thor_fx_manager__maxpoints__disabled_c;
                czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager.Disabled := true;

              end;

          end;
        //---//if czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager <> nil then


        if czo�gi_t[ i ].strza�_prze�adowanie_procent < 100 then
          begin

            czo�gi_t[ i ].strza�_prze�adowanie_procent :=
                100
              * Czas_Mi�dzy_W_Milisekundach( czo�gi_t[ i ].strza�_poprzedni_milisekundy_czas_i, true )
              / strza�_prze�adowanie_czas_milisekundy_c;


            if czo�gi_t[ i ].bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i <> 0 then
              czo�gi_t[ i ].strza�_prze�adowanie_procent := 2 * czo�gi_t[ i ].strza�_prze�adowanie_procent;


            if czo�gi_t[ i ].strza�_prze�adowanie_procent > 100 then
              czo�gi_t[ i ].strza�_prze�adowanie_procent := 100;


            if    ( czo�gi_t[ i ].strza�_prze�adowanie_procent >= 100 )
              and ( czo�gi_t[ i ].celownicza_linia.NodesAspect <> lnaAxes ) then
              czo�gi_t[ i ].celownicza_linia.NodesAspect := lnaAxes;

          end;
        //---//if czo�gi_t[ i ].strza�_prze�adowanie_procent < 100 then


        czo�gi_t[ i ].Lufa__Odrzut_Przesuni�cie_Ustaw();


        // Bonusy czo�gu.
        if    ( czo�gi_t[ i ].bonus__jazda_szybsza__zdobycie_sekundy_czas_i <> 0 )
          and (  Czas_Mi�dzy_W_Sekundach( czo�gi_t[ i ].bonus__jazda_szybsza__zdobycie_sekundy_czas_i ) > bonus_czo�gu_trwanie_czas_sekundy_c  ) then
          czo�gi_t[ i ].bonus__jazda_szybsza__zdobycie_sekundy_czas_i := 0;

        if    ( czo�gi_t[ i ].bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i <> 0 )
          and (  Czas_Mi�dzy_W_Sekundach( czo�gi_t[ i ].bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i ) > bonus_czo�gu_trwanie_czas_sekundy_c  ) then
          czo�gi_t[ i ].bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i := 0;
        //---// Bonusy czo�gu.


        if czo�gi_t[ i ].celownik__koryguj_o_si��_wiatru then
          czo�gi_t[ i ].Celownik_Wylicz( Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value );


        if czo�gi_t[ i ].celownicza_linia.Visible then
          begin

           if czo�gi_t[ i ].strza�_prze�adowanie_procent = 100 then
             czo�gi_t[ i ].celownicza_linia.LinePattern := $FFFF // Ci�g�a.
           else//if czo�gi_t[ i ].strza�_prze�adowanie_procent = 100 then
             czo�gi_t[ i ].celownicza_linia.LinePattern := $CCCC // Punktowana.

          end;
        //---//if czo�gi_t[ i ].celownicza_linia.Visible then

      end;
    //---//if czo�gi_t[ i ] <> nil then

end;//---//Funkcja Czo�gi_Parametry_Aktualizuj().

//Funkcja Czo�g_Gracza_Indeks_Tabeli_Ustal().
function TCzolgi_Form.Czo�g_Gracza_Indeks_Tabeli_Ustal( const czy_gracz_2_f : boolean = false ) : integer;
begin

  Result := -99;

  if not czy_gracz_2_f then
    begin

      // Gracz 1.

      if Gracz__1__Czo�g_Wybrany__Lewo__D�_RadioButton.Checked then
        Result := 1
      else
      if Gracz__1__Czo�g_Wybrany__Lewo__G�ra_RadioButton.Checked then
        Result := 3
      else
      if Gracz__1__Czo�g_Wybrany__Prawo__D�_RadioButton.Checked then
        Result := 2
      else
      if Gracz__1__Czo�g_Wybrany__Prawo__G�ra_RadioButton.Checked then
        Result := 4;

    end
  else//if not czy_gracz_2_f then
    begin

      // Gracz 2.

      if Gracz__2__Czo�g_Wybrany__Lewo__D�_RadioButton.Checked then
        Result := 1
      else
      if Gracz__2__Czo�g_Wybrany__Lewo__G�ra_RadioButton.Checked then
        Result := 3
      else
      if Gracz__2__Czo�g_Wybrany__Prawo__D�_RadioButton.Checked then
        Result := 2
      else
      if Gracz__2__Czo�g_Wybrany__Prawo__G�ra_RadioButton.Checked then
        Result := 4;

    end;
  //---//if not czy_gracz_2_f then

end;//---//Czo�g_Gracza_Indeks_Tabeli_Ustal().

//Funkcja Interfejs_Wska�niki_Ustaw().
procedure TCzolgi_Form.Interfejs_Wska�niki_Ustaw( const oczekiwanie_pomi�_f : boolean = false );

  //Funkcja T�o_Pozycja_Ustaw() w Interfejs_Wska�niki_Ustaw().
  procedure T�o_Pozycja_Ustaw( gl_hud_sprite_f : TGLHUDSprite; const czo�g_indeks_f : integer; const czy_gracz_2_f : boolean = false );
  begin

    gl_hud_sprite_f.Width := 340; // Domy�lna szeroko�� t�a napis�w interfejsu gracza.

    if czo�gi_t[ czo�g_indeks_f ] <> nil then
      begin

        if czo�gi_t[ czo�g_indeks_f ].strza�_prze�adowanie_procent < 100 then
          gl_hud_sprite_f.Width := gl_hud_sprite_f.Width + 55;

        if czo�gi_t[ czo�g_indeks_f ].bonus__jazda_szybsza__zdobycie_sekundy_czas_i <> 0 then
          gl_hud_sprite_f.Width := gl_hud_sprite_f.Width + 60;

        if czo�gi_t[ czo�g_indeks_f ].bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i <> 0 then
          gl_hud_sprite_f.Width := gl_hud_sprite_f.Width + 60;


        if   (
                   ( not czy_gracz_2_f )
               and ( Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex = 1 ) // m/s.
             )
          or (
                   ( czy_gracz_2_f )
               and ( Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex = 1 ) // m/s.
             ) then
          gl_hud_sprite_f.Width := gl_hud_sprite_f.Width + 20;

      end;
    //---//if czo�gi_t[ czo�g_indeks_f ] <> nil then


    // Nieparzyste lewo, parzyste prawo.

    if czo�g_indeks_f mod 2 = 0 then
      gl_hud_sprite_f.Position.X := Gra_GLSceneViewer.Width - gl_hud_sprite_f.Width * 0.5 - 5 // Prawo
    else//if not czy_prawo_f then
      gl_hud_sprite_f.Position.X := gl_hud_sprite_f.Width * 0.5 + 5; // Lewo.


    if czo�g_indeks_f > 2 then
      gl_hud_sprite_f.Position.Y := gl_hud_sprite_f.Height * 0.5 + 5 // G�ra.
    else//if czo�g_indeks_f > 2 then
      gl_hud_sprite_f.Position.Y := Gra_GLSceneViewer.Height - gl_hud_sprite_f.Height * 0.5 - 5; // D�.


    if    ( czo�gi_t[ czo�g_indeks_f ] <> nil )
      and (  not GLS.VectorGeometry.VectorEquals( gl_hud_sprite_f.Material.FrontProperties.Diffuse.Color, czo�gi_t[ czo�g_indeks_f ].kad�ub.Material.FrontProperties.Emission.Color )  ) then
      gl_hud_sprite_f.Material.FrontProperties.Diffuse.Color := czo�gi_t[ czo�g_indeks_f ].kad�ub.Material.FrontProperties.Emission.Color;


    if not gl_hud_sprite_f.Visible then
      gl_hud_sprite_f.Visible := true;

  end;//---//Funkcja T�o_Pozycja_Ustaw() w Interfejs_Wska�niki_Ustaw().

  //Funkcja Napis_Pozycja_Ustaw() w Interfejs_Wska�niki_Ustaw().
  procedure Napis_Pozycja_Ustaw( gl_hud_text_f : TGLHUDText; gl_hud_sprite_f : TGLHUDSprite );
  begin

    gl_hud_text_f.Position.X := gl_hud_sprite_f.Position.X - gl_hud_sprite_f.Width * 0.5 + 10;
    gl_hud_text_f.Position.Y := gl_hud_sprite_f.Position.Y - GLWindowsBitmapFont1.Font.Size; // 15

  end;//---//Funkcja Napis_Pozycja_Ustaw() w Interfejs_Wska�niki_Ustaw().

  //Funkcja Napis_Tre��_Ustaw() w Interfejs_Wska�niki_Ustaw().
  procedure Napis_Tre��_Ustaw( czo�g_f : TCzo�g; gl_hud_text_f : TGLHUDText; const czy_gracz_2_f : boolean = false );
  var
    amunicja_pr�dko��_ustawiona_jednostka_ms : boolean;
    ztd : double;
    zts : string;
  begin

    if czo�g_f = nil then
      Exit;


    gl_hud_text_f.Text := t�umaczenie_komunikaty_r.s�owo__gracz__skr�t;

    if not czy_gracz_2_f then
      begin

        gl_hud_text_f.Text := gl_hud_text_f.Text + ' 1';
        amunicja_pr�dko��_ustawiona_jednostka_ms := Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex = 1; // m/s.

      end
    else//if not czy_gracz_2_f then
      begin

        gl_hud_text_f.Text := gl_hud_text_f.Text + ' 2';
        amunicja_pr�dko��_ustawiona_jednostka_ms := Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex = 1; // m/s.

      end;
    //---//if not czy_gracz_2_f then


    if amunicja_pr�dko��_ustawiona_jednostka_ms then
      begin

        ztd := czo�g_f.amunicja_pr�dko��_ustawiona;

        zts := 'm/s';

      end
    else//if amunicja_pr�dko��_ustawiona_jednostka_ms then
      begin

        ztd :=
            100
          * ( czo�g_f.amunicja_pr�dko��_ustawiona - amunicja_pr�dko��_ustawiona__minimalna_c )
          / ( amunicja_pr�dko��_ustawiona__maksymalna_c - amunicja_pr�dko��_ustawiona__minimalna_c );

        zts := '%';

      end;
    //---//if amunicja_pr�dko��_ustawiona_jednostka_ms then


    gl_hud_text_f.Text := gl_hud_text_f.Text +
      ', / ' + Trim(  FormatFloat( '### ### ##0.00', czo�g_f.lufa_gl_dummy_cube.RollAngle )  ) +
      '*, >> ' +
      Trim(  FormatFloat( '### ### ##0.00', ztd )  ) +
      ' ' + zts + ', ';

    //gl_hud_text_f.Text := gl_hud_text_f.Text +
    //  Trim(  FormatFloat( '### ### ##0.00', czo�g_f.amunicja_pr�dko��_ustawiona )  ) + ', ';


    if czo�g_f.strza�_prze�adowanie_procent < 100 then
      gl_hud_text_f.Text := gl_hud_text_f.Text +
        '(' + Trim(  FormatFloat( '### ### ##0', czo�g_f.strza�_prze�adowanie_procent )  ) + '%)'
    else//if czo�g_f.strza�_prze�adowanie_procent < 100 then
      gl_hud_text_f.Text := gl_hud_text_f.Text +
        'V';


    if czo�g_f.bonus__jazda_szybsza__zdobycie_sekundy_czas_i <> 0 then
      gl_hud_text_f.Text := gl_hud_text_f.Text +
        ', <' + Trim(   FormatFloat(  '### ### ##0', bonus_czo�gu_trwanie_czas_sekundy_c - Czas_Mi�dzy_W_Sekundach( czo�g_f.bonus__jazda_szybsza__zdobycie_sekundy_czas_i )  )   ) + '>';

    if czo�g_f.bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i <> 0 then
      gl_hud_text_f.Text := gl_hud_text_f.Text +
        ', (' + Trim(   FormatFloat(  '### ### ##0', bonus_czo�gu_trwanie_czas_sekundy_c - Czas_Mi�dzy_W_Sekundach( czo�g_f.bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i )  )   ) + ')';

  end;//---//Funkcja Napis_Tre��_Ustaw() w Interfejs_Wska�niki_Ustaw().

var
  zti : integer;
begin//Funkcja Interfejs_Wska�niki_Ustaw().

  // Gdy GLHUDText jest w GLHUDSprite trzeba ustawia� pozycj� ale nie trzeba ustawia� widoczno�ci.

  if    ( not oczekiwanie_pomi�_f )
    and (  MilliSecondsBetween( Now(), napis_od�wie�__ostatnie_wywo�anie_g ) < 300  ) then // Aby za cz�sto nie od�wie�a�o wska�nik�w interfejsu.
    Exit;

  Punkty__Lewo__GLHUDSprite.Position.X := Gra_GLSceneViewer.Width * 0.5 - Punkty__Lewo__GLHUDSprite.Width * 0.5;
  Punkty__Prawo__GLHUDSprite.Position.X := Punkty__Lewo__GLHUDSprite.Position.X + Punkty__Lewo__GLHUDSprite.Width;
  Punkty__Lewo__GLHUDText.Position.X := Punkty__Lewo__GLHUDSprite.Position.X + Punkty__Lewo__GLHUDSprite.Width * 0.5 - 10;
  Punkty__Prawo_GLHUDText.Position.X := Punkty__Lewo__GLHUDSprite.Position.X + Punkty__Lewo__GLHUDSprite.Width * 0.5 + 10;
  Punkty__Separator_GLHUDText.Position.X := Punkty__Lewo__GLHUDSprite.Position.X + Punkty__Lewo__GLHUDSprite.Width * 0.5;

  Punkty__Lewo__GLHUDText.Text := Trim(  FormatFloat( '### ### ##0', punkty__lewo )  );
  Punkty__Prawo_GLHUDText.Text := Trim(  FormatFloat( '### ### ##0', punkty__prawo )  );

  Gracz__1__Czo�g_Wybrany_GroupBox.Caption := t�umaczenie_komunikaty_r.s�owo__gracz + ' 1: ' + Trim(  FormatFloat( '### ### ##0', punkty__gracz__1 )  );
  Gracz__2__Czo�g_Wybrany_GroupBox.Caption := t�umaczenie_komunikaty_r.s�owo__gracz + ' 2: ' + Trim(  FormatFloat( '### ### ##0', punkty__gracz__2 )  );

  GLWindowsBitmapFont1.EnsureString( Punkty__Lewo__GLHUDText.Text );
  GLWindowsBitmapFont1.EnsureString( Punkty__Prawo_GLHUDText.Text );
  GLWindowsBitmapFont1.EnsureString( Punkty__Separator_GLHUDText.Text );


  zti := Czo�g_Gracza_Indeks_Tabeli_Ustal();

  if zti <> -99 then
    begin

      T�o_Pozycja_Ustaw( Gracz__1__GLHUDSprite, zti );
      Napis_Pozycja_Ustaw( Gracz__1__GLHUDText, Gracz__1__GLHUDSprite );
      Napis_Tre��_Ustaw( czo�gi_t[ zti ], Gracz__1__GLHUDText );

      GLWindowsBitmapFont1.EnsureString( Gracz__1__GLHUDText.Text );

    end
  else//if zti <> -99 then
    if Gracz__1__GLHUDSprite.Visible then
      Gracz__1__GLHUDSprite.Visible := false;


  zti := Czo�g_Gracza_Indeks_Tabeli_Ustal( true );

  if zti <> -99 then
    begin

      T�o_Pozycja_Ustaw( Gracz__2__GLHUDSprite, zti, true );
      Napis_Pozycja_Ustaw( Gracz__2__GLHUDText, Gracz__2__GLHUDSprite );
      Napis_Tre��_Ustaw( czo�gi_t[ zti ], Gracz__2__GLHUDText, true );

      GLWindowsBitmapFont1.EnsureString( Gracz__2__GLHUDText.Text );

    end
  else//if zti <> -99 then
    if Gracz__2__GLHUDSprite.Visible then
      Gracz__2__GLHUDSprite.Visible := false;


  napis_od�wie�__ostatnie_wywo�anie_g := Now();


  Dzie�_Noc_GLHUDSprite.Position.X := Gra_GLSceneViewer.Width * 0.5;
  Dzie�_Noc_GLHUDSprite.Position.Y := Gra_GLSceneViewer.Height * 0.5;

  Dzie�_Noc_GLHUDSprite.Height := Gra_GLSceneViewer.Height;
  Dzie�_Noc_GLHUDSprite.Width := Gra_GLSceneViewer.Width;

end;//---//Interfejs_Wska�niki_Ustaw().

//Funkcja Las_Sosnowy_Utw�rz().
procedure TCzolgi_Form.Las_Sosnowy_Utw�rz();

  //Funkcja Las_Cz��_Utw�rz() w Las_Sosnowy_Utw�rz().
  procedure Las_Cz��_Utw�rz( const czy_prawa_strona_f : boolean = false );
  const
    czo�g_odst�p_c_l : single = 3;
    sosny_ilo��__x_c_l : integer = 20;
    sosny_ilo��__z_c_l : integer = 10;
  var
    i,
    j,
    zti,
    czo�gi_indeks_l
      : integer;
  begin

    for i := 0 to sosny_ilo��__x_c_l - 1 do
      for j := 0 to sosny_ilo��__z_c_l - 1 do
        begin

          zti := Length( sosny_gl_proxy_object_t );
          SetLength( sosny_gl_proxy_object_t, zti + 1 );

          sosny_gl_proxy_object_t[ zti ] := TGLProxyObject.Create( Gra_Obiekty_GLDummyCube );
          sosny_gl_proxy_object_t[ zti ].Parent := Gra_Obiekty_GLDummyCube;
          sosny_gl_proxy_object_t[ zti ].MoveFirst(); // Aby nie przes�ania�o efekt�w.
          sosny_gl_proxy_object_t[ zti ].MasterObject := sosna;
          sosny_gl_proxy_object_t[ zti ].Position.X := -15 * i + (  Random( 13 ) - 6  ); // Wsp�rz�dne GLProxyObject maj� punkt zero w miejscu gdzie jest MasterObject.

          if czy_prawa_strona_f then
            //sosny_gl_proxy_object_t[ zti ].Position.X := -sosna.Position.X * 2 + 15 * i + (  Random( 13 ) - 6  );
            sosny_gl_proxy_object_t[ zti ].Position.X := -sosna.Position.X * 2 - sosny_gl_proxy_object_t[ zti ].Position.X;

          sosny_gl_proxy_object_t[ zti ].Position.Z := -15 * j + (  Random( 13 ) - 6  );


          // Przesuwa sosny aby czo�gi je�d��ce po lesie nie przenika�y przez drzewa.
          czo�gi_indeks_l := 5;

          while czo�gi_indeks_l < Length( czo�gi_t ) do
            begin

              //if Abs(  czo�gi_t[ czo�gi_indeks_l ].Position.Z - sosna.LocalToAbsolute( sosny_gl_proxy_object_t[ zti ].Position.AsVector ).Z  ) <= czo�g_odst�p_c_l then
              if Abs(  czo�gi_t[ czo�gi_indeks_l ].Position.Z - sosny_gl_proxy_object_t[ zti ].MasterObject.LocalToAbsolute( sosny_gl_proxy_object_t[ zti ].Position.AsVector ).Z  ) <= czo�g_odst�p_c_l then
                if sosny_gl_proxy_object_t[ zti ].MasterObject.LocalToAbsolute( sosny_gl_proxy_object_t[ zti ].Position.AsVector ).Z <= czo�gi_t[ czo�gi_indeks_l ].Position.Z then
                  sosny_gl_proxy_object_t[ zti ].Position.Z := sosny_gl_proxy_object_t[ zti ].Position.Z - czo�g_odst�p_c_l
                else//if sosny_gl_proxy_object_t[ zti ].MasterObject.LocalToAbsolute( sosny_gl_proxy_object_t[ zti ].Position.AsVector ).Z <= czo�gi_t[ czo�gi_indeks_l ].Position.Z then
                  sosny_gl_proxy_object_t[ zti ].Position.Z := sosny_gl_proxy_object_t[ zti ].Position.Z + czo�g_odst�p_c_l;

              czo�gi_indeks_l := czo�gi_indeks_l + 2;

            end;
          //---//while czo�gi_indeks_l < Length( czo�gi_t ) do

        end;
      //---//for j := 0 to sosny_ilo��__z_c_l - 1 do

  end;//---//Funkcja Las_Cz��_Utw�rz() w Las_Sosnowy_Utw�rz().

begin//Funkcja Las_Sosnowy_Utw�rz().

  Las_Cz��_Utw�rz(); // Las na lewo.
  Las_Cz��_Utw�rz( true ); // Las na prawo.

end;//---//Funkcja Las_Sosnowy_Utw�rz().

//Funkcja Wiatr_Si�a_Wylicz().
procedure TCzolgi_Form.Wiatr_Si�a_Wylicz( const delta_czasu_f : double );
var
  zti : integer;
begin

  if Abs( wiatr__si�a_aktualna - wiatr__si�a_docelowa ) > 1 then
    begin

      // Si�a wiatru d��y do zadanej warto�ci.

      if wiatr__si�a_aktualna < wiatr__si�a_docelowa then
        zti := 1
      else//if wiatr__si�a_aktualna < wiatr__si�a_docelowa then
        zti := -1;

      wiatr__si�a_aktualna := wiatr__si�a_aktualna + zti * 10 * delta_czasu_f;

      Efekt__Smuga_GLPerlinPFXManager.Acceleration.X := -wiatr__si�a_aktualna * 0.1; // -1 lewo.
      Efekt__Dym_GLPerlinPFXManager.Acceleration.X := -wiatr__si�a_aktualna * 0.3; // -1 lewo.
      Efekt__Chmury_GLPerlinPFXManager.Acceleration.X := -wiatr__si�a_aktualna * 0.3; // -1 lewo.
      //Chmury_GLDummyCube.Position.X := -wiatr__si�a_aktualna * 4; //???

      //if Efekt__Chmury_GLPerlinPFXManager.LifeColors.Count > 1 then //???
      //  Efekt__Chmury_GLPerlinPFXManager.LifeColors.Items[ 1 ].LifeTime := 8 + Abs( wiatr__si�a_aktualna );

    end
  else//if Abs( wiatr__si�a_aktualna - wiatr__si�a_docelowa ) > 1 then
    if Wiatr_Si�a_SpinEdit.Value <> 0 then
      begin

        // Wiatr osi�gn�� zadan� si��, ustawia odliczanie do zmiany si�y wiatru.

        if wiatr__kolejne_wyliczenie__za_sekundy_czas_i = 0 then
          begin

            wiatr__kolejne_wyliczenie__za_sekundy_czas_i := Random( wiatr__kolejne_wyliczenie__za__losuj_z_sekundy_c );
            wiatr__kolejne_wyliczenie__odliczanie_od_sekundy_czas_i := Czas_Teraz_W_Sekundach();

          end;
        //---//if wiatr__kolejne_wyliczenie__za_sekundy_czas_i = 0 then


        if Czas_Mi�dzy_W_Sekundach( wiatr__kolejne_wyliczenie__odliczanie_od_sekundy_czas_i ) > wiatr__kolejne_wyliczenie__za_sekundy_czas_i then
          begin

            wiatr__zakres := Wiatr_Si�a_SpinEdit.Value;

            if wiatr__zakres > Wiatr_Si�a_SpinEdit.MaxValue then
              wiatr__zakres := Wiatr_Si�a_SpinEdit.MaxValue
            else//if wiatr__zakres > Wiatr_Si�a_SpinEdit.MaxValue then
            if wiatr__zakres < Wiatr_Si�a_SpinEdit.MinValue then
              wiatr__zakres := Wiatr_Si�a_SpinEdit.MinValue;

            wiatr__si�a_docelowa := Random(  Round( wiatr__zakres ) * 2 + 1 ) - wiatr__zakres;

            wiatr__kolejne_wyliczenie__za_sekundy_czas_i := 0;

          end;
        //---//if Czas_Mi�dzy_W_Sekundach( wiatr__kolejne_wyliczenie__odliczanie_od_sekundy_czas_i ) > wiatr__kolejne_wyliczenie__za_sekundy_czas_i then

      end
    else//if Wiatr_Si�a_SpinEdit.Value <> 0 then
      begin

        // Wiatr_Si�a_SpinEdit.Value = 0.

        if wiatr__si�a_docelowa <> Wiatr_Si�a_SpinEdit.Value then
          wiatr__si�a_docelowa := Wiatr_Si�a_SpinEdit.Value;

        if    ( wiatr__si�a_aktualna <> wiatr__si�a_docelowa )
          and (  Abs( wiatr__si�a_aktualna - wiatr__si�a_docelowa ) < 1  )then
          wiatr__si�a_aktualna := wiatr__si�a_docelowa;

      end;
    //---//if Wiatr_Si�a_SpinEdit.Value <> 0 then

end;//---//Funkcja Wiatr_Si�a_Wylicz().

//Funkcja Wiatr_Si�a_Modyfikacja_O_Ko�ysanie().
function TCzolgi_Form.Wiatr_Si�a_Modyfikacja_O_Ko�ysanie() : double;
begin

  //
  // Funkcja modyfikuje aktualn� si�� wiatru o lekkie podmuchy.
  //
  // Zwraca aktualn� si�� wiatru zmodyfikowan� o lekkie podmuchy.
  //

  Result := wiatr__si�a_aktualna;

  if   ( Wiatr_Si�a_SpinEdit.Value = 0 )
    or ( sosna = nil ) then
    Exit;

  if Wiatr_Si�a_SpinEdit.MaxValue > 0 then
    Result :=
        Result
      + sosna.ko�ysanie_si�__dummy_cube.RollAngle
      //* wiatr__zakres * 100 / Wiatr_Si�a_SpinEdit.MaxValue * 0.01; // Im silniejszy wiatr tym silniejsze podmuchy.
      * wiatr__zakres / Wiatr_Si�a_SpinEdit.MaxValue; // Im silniejszy wiatr tym silniejsze podmuchy. // Uproszczenie oblicze�.

end;//---//Funkcja Wiatr_Si�a_Modyfikacja_O_Ko�ysanie().

//Funkcja Dzie�_Noc_Zmie�().
procedure TCzolgi_Form.Dzie�_Noc_Zmie�( const delta_czasu_f : double );
var
  ztsi : single;
begin

  if Dzie�_Noc_CheckBox.Checked then
    begin

      if noc_zapada then
        ztsi := 1
      else//if noc_zapada then
        ztsi := -1;

      noc_procent := noc_procent + ztsi * 1 * delta_czasu_f;

    end
  else//if Dzie�_Noc_CheckBox.Checked then
    noc_procent := Dzie�_Noc__Procent_TrackBar.Position;


  if noc_procent > 100 then
    noc_procent := 100
  else//if noc_procent > 100 then
  if noc_procent < 0 then
    noc_procent := 0;


  // Najwi�ksza warto�� alfa wynosi 95%.
  //Dzie�_Noc_GLHUDSprite.Material.FrontProperties.Diffuse.Alpha := 95 * noc_procent * 0.01 * 0.01;
  //Dzie�_Noc_GLHUDSprite.Material.FrontProperties.Diffuse.Alpha := noc_procent * 0.0095; // Uproszczenie oblicze�.


  // Noc obejmuje tylko po�ow� doby.
  if noc_procent >= 50 then
    //Dzie�_Noc_GLHUDSprite.Material.FrontProperties.Diffuse.Alpha := ( noc_procent - 50 ) * 2 * 0.0095
    Dzie�_Noc_GLHUDSprite.Material.FrontProperties.Diffuse.Alpha := ( noc_procent - 50 ) * 0.019 // Uproszczenie oblicze�.
  else//if noc_procent >= 50 then
    Dzie�_Noc_GLHUDSprite.Material.FrontProperties.Diffuse.Alpha := 0;


   // Teoretyczna godzina wyliczana na podstawie noc_procent.
  if noc_zapada then
    //ztsi := 12 + 12 * noc_procent * 0.01
    ztsi := 12 + 0.12 * noc_procent // Uproszczenie oblicze�.
  else//if noc_zapada then
    ztsi := 12 * ( 100 - noc_procent ) * 0.01;


  if    ( noc_zapada )
    and ( noc_procent >= 100 ) then
    noc_zapada := false
  else//if    ( noc_zapada ) (...)
  if    ( not noc_zapada )
    and ( noc_procent <= 0 ) then
    noc_zapada := true;


  Godzina_Label.Caption := Trim(   FormatFloat(  '00', Trunc( ztsi )  )   ) + ':' + Trim(   FormatFloat(  '00', 59 * Frac( ztsi )  )   );


  if    ( not noc_zapada )
    and ( not Ranek_Label.Visible )then
    Ranek_Label.Visible := true
  else//if    ( not noc_zapada ) (...)
  if    ( noc_zapada )
    and ( Ranek_Label.Visible )then
    Ranek_Label.Visible := false;


  if noc_procent <= 50 then
    begin

      // S�o�ce.

      ztsi := 100 - noc_procent * 2;

      if S�o�ce_Ksi�yc_GLSphere.Scale.X <> 200 then
        begin

          S�o�ce_Ksi�yc_GLSphere.Scale.SetVector( 200, 200, 200 );
          S�o�ce_Ksi�yc_GLSphere.Material.FrontProperties.Diffuse.Color := GLS.Color.clrYellow;
          S�o�ce_Ksi�yc_GLSphere.Material.FrontProperties.Emission.Color := GLS.Color.clrCoral;

        end;
      //---//if S�o�ce_Ksi�yc_GLSphere.Scale.X <> 200 then

    end
  else//if noc_procent <= 50 then
    begin

      // Ksi�yc.

      ztsi := ( noc_procent - 50 ) * 2;

      if S�o�ce_Ksi�yc_GLSphere.Scale.X <> 100 then
        begin

          S�o�ce_Ksi�yc_GLSphere.Scale.SetVector( 100, 100, 100 );
          S�o�ce_Ksi�yc_GLSphere.Material.FrontProperties.Diffuse.Color := GLS.Color.clrWhite;
          S�o�ce_Ksi�yc_GLSphere.Material.FrontProperties.Emission.Color := GLS.Color.clrDarkTurquoise;

        end;
      //---//if S�o�ce_Ksi�yc_GLSphere.Scale.X <> 100 then

    end;
  //---//if noc_procent <= 50 then

  //S�o�ce_Ksi�yc_GLSphere.Position.Y := -100 + 1000 * noc_procent * 0.01;
  S�o�ce_Ksi�yc_GLSphere.Position.Y := -200 + 1000 * ztsi * 0.01;

  Gra_GLLightSource.Position.Y := S�o�ce_Ksi�yc_GLSphere.Position.Y + 500;

end;//---//Funkcja Dzie�_Noc_Zmie�().

//Funkcja Dzie�_Noc_Zmie�__Procent_Wed�ug_Czasu_Systemowego_Ustaw().
procedure TCzolgi_Form.Dzie�_Noc_Zmie�__Procent_Wed�ug_Czasu_Systemowego_Ustaw();
var
  godzina,
  minuta
    : real;
  ztt : TTime;
begin

  // Zamienia aktualny czas na warto�� procentow� z 12 godzin.

  ztt := Time();
  godzina := HourOf( ztt );
  minuta := MinuteOf( ztt );

  noc_zapada := godzina >= 12;

  if godzina >= 12 then
    godzina := godzina - 12;

  minuta := ( 100 * minuta / 60 ) * 0.01; // Zamienia minuty na setne warto�ci liczby.

  godzina := godzina + minuta;

  noc_procent := 100 * godzina / 12;

  if not noc_zapada then
    noc_procent := 100 - noc_procent;


  Dzie�_Noc__Procent_TrackBar.Position := Round( noc_procent ); // Wywo�a Dzie�_Noc__Procent_TrackBarChange().

end;//---//Funkcja Dzie�_Noc_Zmie�__Procent_Wed�ug_Czasu_Systemowego_Ustaw().

//Funkcja Nazwa_Klawisza().
function TCzolgi_Form.Nazwa_Klawisza( const klawisz_f : word ) : string;
var
  bufor : array [ 0..255 ] of Char;
begin

  //
  // Funkcja okre�la nazw� klawisz.
  //
  // Zwraca okre�la nazw� klawisz.
  //

  if klawisz_f = 0 then
    Result := '<brak>'
  else
  if klawisz_f = 19 then
    Result := 'Pause Break'
  else
  if klawisz_f = 33 then
    Result := 'Page Up'
  else
  if klawisz_f = 34 then
    Result := 'Page Down'
  else
  if klawisz_f = 35 then
    Result := 'End'
  else
  if klawisz_f = 36 then
    Result := 'Home'
  else
  if klawisz_f = 37 then
    Result := 'Kursor lewo'
  else
  if klawisz_f = 38 then
    Result := 'Kursor g�ra'
  else
  if klawisz_f = 39 then
    Result := 'Kursor prawo'
  else
  if klawisz_f = 40 then
    Result := 'Kursor d�'
  else
  if klawisz_f = 45 then
    Result := 'Insert'
  else
  if klawisz_f = 46 then
    Result := 'Delete'
  else
  if klawisz_f = 91 then
    Result := 'Windows lewy'
  else
  if klawisz_f = 92 then
    Result := 'Windows prawy'
  else
  if klawisz_f = 93 then
    Result := 'Menu'
  else
  if klawisz_f = 111 then
    Result := 'Num /'
  else
  if klawisz_f = 144 then
    Result := 'Num Lock'
  else
    begin

      GetKeyNameText(  MapVirtualKey( klawisz_f, 0  ) shl 16, bufor, 256  );
      Result := bufor;

    end;
  //---//

end;//---//Funkcja Nazwa_Klawisza().

//Funkcja Klawiatura_Konfiguracja__Niepowtarzalno��_Sprawd�().
procedure TCzolgi_Form.Klawiatura_Konfiguracja__Niepowtarzalno��_Sprawd�();

  //Funkcja Niepowtarzalno��_Tag_Sprawd�() w Klawiatura_Konfiguracja__Niepowtarzalno��_Sprawd�().
  function Niepowtarzalno��_Tag_Sprawd�( const zt_edit_f : TEdit ) : boolean;
  var
    i_l,
    j_l
      : integer;
  begin

    Result := false;

    if zt_edit_f = nil then
      Exit;

    for i_l := 0 to Klawiatura_Konfiguracja_GroupBox.ControlCount - 1 do // Tylko wizualne. Wa�ny jest rodzic (Parent, nie Owner - Create( ScrollBox1 )).
      if Klawiatura_Konfiguracja_GroupBox.Controls[ i_l ].ClassType = TGroupBox then
        for j_l := 0 to TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i_l ]).ControlCount - 1 do // Tylko wizualne. Wa�ny jest rodzic (Parent, nie Owner - Create( ScrollBox1 )).
          if    ( TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i_l ]).Controls[ j_l ].ClassType = TEdit )
            and ( TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i_l ]).Controls[ j_l ]) <> zt_edit_f )
            and ( TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i_l ]).Controls[ j_l ]).Tag <> 0 ) // Brak/
            and ( TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i_l ]).Controls[ j_l ]).Tag = zt_edit_f.Tag ) then
            begin

              TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i_l ]).Controls[ j_l ]).Color := $00E1E1FF;

              if not Result then
                Result := true;

            end;
          //---//if    ( TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i_l ]).Controls[ j_l ].ClassType = TEdit ) (...)

  end;//---//Funkcja Niepowtarzalno��_Tag_Sprawd�() w Klawiatura_Konfiguracja__Niepowtarzalno��_Sprawd�().

var
  i,
  j
    : integer;
begin//Funkcja Klawiatura_Konfiguracja__Niepowtarzalno��_Sprawd�().

  // Ustawia domy�lny kolor.
  for i := 0 to Klawiatura_Konfiguracja_GroupBox.ControlCount - 1 do // Tylko wizualne. Wa�ny jest rodzic (Parent, nie Owner - Create( ScrollBox1 )).
    if Klawiatura_Konfiguracja_GroupBox.Controls[ i ].ClassType = TGroupBox then
      for j := 0 to TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).ControlCount - 1 do // Tylko wizualne. Wa�ny jest rodzic (Parent, nie Owner - Create( ScrollBox1 )).
        if TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).Controls[ j ].ClassType = TEdit then
          if TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).Controls[ j ]).Tag = 0 then // Brak.
            TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).Controls[ j ]).Color := clInactiveCaption
          else//if TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).Controls[ j ]).Tag = 0 then
            TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).Controls[ j ]).Color := clWindow;


  for i := 0 to Klawiatura_Konfiguracja_GroupBox.ControlCount - 1 do // Tylko wizualne. Wa�ny jest rodzic (Parent, nie Owner - Create( ScrollBox1 )).
    if Klawiatura_Konfiguracja_GroupBox.Controls[ i ].ClassType = TGroupBox then
      for j := 0 to TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).ControlCount - 1 do // Tylko wizualne. Wa�ny jest rodzic (Parent, nie Owner - Create( ScrollBox1 )).
        if    ( TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).Controls[ j ].ClassType = TEdit )
          and (  Niepowtarzalno��_Tag_Sprawd�( TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).Controls[ j ]) )  ) then
          TEdit(TGroupBox(Klawiatura_Konfiguracja_GroupBox.Controls[ i ]).Controls[ j ]).Color := $00E1E1FF;

end;//---//Funkcja Klawiatura_Konfiguracja__Niepowtarzalno��_Sprawd�().

//Funkcja Ustawienia_Plik().
procedure TCzolgi_Form.Ustawienia_Plik( const zapisuj_ustawienia_f : boolean = false );

  //Funkcja Boolean_W__Tak_Nie() w Ustawienia_Plik().
  function Boolean_W__Tak_Nie( const ztb_f : boolean ) : string;
  begin

    //
    // Funkcja zamienia warto�� boolean na napis.
    //
    // Zwraca tak lub nie.
    //

    if ztb_f then
      Result := 'tak'
    else//if ztb_f then
      Result := 'nie'

  end;//---//Funkcja Boolean_W__Tak_Nie() w Ustawienia_Plik().

var
  plik_ini : System.IniFiles.TIniFile;
  zti : integer;
  zts : string;
  tekst_string_list : TStringList;
begin//Funkcja Ustawienia_Plik().

  //
  // Funkcja wczytuje i zapisuje ustawienia.
  //
  // Parametry:
  //   zapisuj_ustawienia_f:
  //     false - tylko odczytuje ustawienia.
  //     true - zapisuje ustawienia.
  //

  zts := ExtractFilePath( Application.ExeName ) + 'Czo�gi.ini';

  plik_ini := TIniFile.Create( zts );


  {$region 'GRA.'}
  zts := Boolean_W__Tak_Nie( Celownicza_Linia_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'celownicza_linia' )  ) then
    plik_ini.WriteString( 'GRA', 'celownicza_linia', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'celownicza_linia', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Celownicza_Linia_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'celownicza_linia__koryguj_o_si��_wiatru' )  ) then
    plik_ini.WriteString( 'GRA', 'celownicza_linia__koryguj_o_si��_wiatru', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'celownicza_linia__koryguj_o_si��_wiatru', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zti := Celownicza_Linia_Wysoko��_SpinEdit.Value;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'celownicza_linia__wysoko��' )  ) then
    plik_ini.WriteInteger( 'GRA', 'celownicza_linia__wysoko��', zti )
  else
    zti := plik_ini.ReadInteger( 'GRA', 'celownicza_linia__wysoko��', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Celownicza_Linia_Wysoko��_SpinEdit.Value := zti;


  zts := Boolean_W__Tak_Nie( Czo�gi_Linia__3_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'czo�gi_linia__3' )  ) then
    plik_ini.WriteString( 'GRA', 'czo�gi_linia__3', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'czo�gi_linia__3', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Czo�gi_Linia__3_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Czo�gi_Linia__4_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'czo�gi_linia__4' )  ) then
    plik_ini.WriteString( 'GRA', 'czo�gi_linia__4', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'czo�gi_linia__4', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Czo�gi_Linia__4_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Dzie�_Noc_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'dzie�_noc' )  ) then
    plik_ini.WriteString( 'GRA', 'dzie�_noc', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'dzie�_noc', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Dzie�_Noc_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Dzie�_Noc__Czas_Systemowy_Ustaw_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'dzie�_noc__czas_systemowy_ustaw' )  ) then
    plik_ini.WriteString( 'GRA', 'dzie�_noc__czas_systemowy_ustaw', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'dzie�_noc__czas_systemowy_ustaw', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Dzie�_Noc__Czas_Systemowy_Ustaw_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  // Najpierw wczyta� noc_procent, potem noc_zapada aby nie nadpisa� warto�ci noc_zapada. //!!!
  zti := Dzie�_Noc__Procent_TrackBar.Position;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'dzie�_noc__procent' )  ) then
    plik_ini.WriteInteger( 'GRA', 'dzie�_noc__procent', zti )
  else
    zti := plik_ini.ReadInteger( 'GRA', 'dzie�_noc__procent', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Dzie�_Noc__Procent_TrackBar.Position := zti;

  if not zapisuj_ustawienia_f then
    noc_procent := Dzie�_Noc__Procent_TrackBar.Position;


  // Najpierw wczyta� noc_procent, potem noc_zapada aby nie nadpisa� warto�ci noc_zapada. //!!!
  zts := Boolean_W__Tak_Nie( noc_zapada );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'dzie�_noc__noc_zapada' )  ) then
    plik_ini.WriteString( 'GRA', 'dzie�_noc__noc_zapada', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'dzie�_noc__noc_zapada', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  if not zapisuj_ustawienia_f then
    noc_zapada := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Efekty__Chmury_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'efekty__chmury' )  ) then
    plik_ini.WriteString( 'GRA', 'efekty__chmury', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'efekty__chmury', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  if not zapisuj_ustawienia_f then
    begin

      Efekty__Chmury_CheckBox.OnClick := nil; // Aby nie wywo�ywa� w tym momencie zdarzenia.

      Efekty__Chmury_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );

      Efekty__Chmury_CheckBox.OnClick := Efekty__Chmury_CheckBoxClick;

    end;
  //---//if not zapisuj_ustawienia_f then


  zts := Boolean_W__Tak_Nie( Efekty__Dym_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'efekty__dym' )  ) then
    plik_ini.WriteString( 'GRA', 'efekty__dym', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'efekty__dym', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  if not zapisuj_ustawienia_f then
    Efekty__Dym_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Efekty__Lufa_Wystrza�_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'efekty__lufa_wystrza�' )  ) then
    plik_ini.WriteString( 'GRA', 'efekty__lufa_wystrza�', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'efekty__lufa_wystrza�', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  if not zapisuj_ustawienia_f then
    begin

      Efekty__Lufa_Wystrza�_CheckBox.OnClick := nil; // Aby nie wywo�ywa� w tym momencie zdarzenia.

      Efekty__Lufa_Wystrza�_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );

      Efekty__Lufa_Wystrza�_CheckBox.OnClick := Efekty__Czo�gi__Utw�rz__Zwolnij_CheckBoxClick;

    end;
  //---//if not zapisuj_ustawienia_f then


  zts := Boolean_W__Tak_Nie( Efekty__Prezent_Zebranie_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'efekty__prezent_zebranie' )  ) then
    plik_ini.WriteString( 'GRA', 'efekty__prezent_zebranie', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'efekty__prezent_zebranie', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  if not zapisuj_ustawienia_f then
    Efekty__Prezent_Zebranie_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Efekty__Smuga_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'efekty__smuga' )  ) then
    plik_ini.WriteString( 'GRA', 'efekty__smuga', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'efekty__smuga', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  if not zapisuj_ustawienia_f then
    Efekty__Smuga_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Efekty__Trafienie_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'efekty__trafienie' )  ) then
    plik_ini.WriteString( 'GRA', 'efekty__trafienie', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'efekty__trafienie', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  if not zapisuj_ustawienia_f then
    begin

      Efekty__Trafienie_CheckBox.OnClick := nil; // Aby nie wywo�ywa� w tym momencie zdarzenia.

      Efekty__Trafienie_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );

      Efekty__Trafienie_CheckBox.OnClick := Efekty__Czo�gi__Utw�rz__Zwolnij_CheckBoxClick;

    end;
  //---//if not zapisuj_ustawienia_f then


  zts := Boolean_W__Tak_Nie( Efekty__Trafienie__Alternatywny_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'efekty__trafienie__alternatywny' )  ) then
    plik_ini.WriteString( 'GRA', 'efekty__trafienie__alternatywny', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'efekty__trafienie__alternatywny', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  if not zapisuj_ustawienia_f then
    begin

      Efekty__Trafienie__Alternatywny_CheckBox.OnClick := nil; // Aby nie wywo�ywa� w tym momencie zdarzenia.

      Efekty__Trafienie__Alternatywny_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );

      Efekty__Trafienie__Alternatywny_CheckBox.OnClick := Efekty__Czo�gi__Utw�rz__Zwolnij_CheckBoxClick;

    end;
  //---//if not zapisuj_ustawienia_f then


  zts := Boolean_W__Tak_Nie( Gracz__1__Akceptuje_Si_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'gracz__1__akceptuje_si' )  ) then
    plik_ini.WriteString( 'GRA', 'gracz__1__akceptuje_si', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'gracz__1__akceptuje_si', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Gracz__1__Akceptuje_Si_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Gracz__2__Akceptuje_Si_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'gracz__2__akceptuje_si' )  ) then
    plik_ini.WriteString( 'GRA', 'gracz__2__akceptuje_si', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'gracz__2__akceptuje_si', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Gracz__2__Akceptuje_Si_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zti := Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'gracz__1__amunicja_pr�dko��_ustawiona_jednostka' )  ) then
    plik_ini.WriteInteger( 'GRA', 'gracz__1__amunicja_pr�dko��_ustawiona_jednostka', zti )
  else
    zti := plik_ini.ReadInteger( 'GRA', 'gracz__1__amunicja_pr�dko��_ustawiona_jednostka', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex := zti;


  zti := Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'gracz__2__amunicja_pr�dko��_ustawiona_jednostka' )  ) then
    plik_ini.WriteInteger( 'GRA', 'gracz__2__amunicja_pr�dko��_ustawiona_jednostka', zti )
  else
    zti := plik_ini.ReadInteger( 'GRA', 'gracz__2__amunicja_pr�dko��_ustawiona_jednostka', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex := zti;


  zti := Czo�g_Gracza_Indeks_Tabeli_Ustal();

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'gracz__1__indeks' )  ) then
    plik_ini.WriteInteger( 'GRA', 'gracz__1__indeks', zti )
  else
    zti := plik_ini.ReadInteger( 'GRA', 'gracz__1__indeks', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  case zti of
      1 : Gracz__1__Czo�g_Wybrany__Lewo__D�_RadioButton.Checked := true;
      2 : Gracz__1__Czo�g_Wybrany__Prawo__D�_RadioButton.Checked := true;
      3 : Gracz__1__Czo�g_Wybrany__Lewo__G�ra_RadioButton.Checked := true;
      4 : Gracz__1__Czo�g_Wybrany__Prawo__G�ra_RadioButton.Checked := true;
      else//case zti of
        Gracz__1__Czo�g_Wybrany__Brak_RadioButton.Checked := true;
    end;
  //---//case zti of


  zti := Czo�g_Gracza_Indeks_Tabeli_Ustal( true );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'gracz__2__indeks' )  ) then
    plik_ini.WriteInteger( 'GRA', 'gracz__2__indeks', zti )
  else
    zti := plik_ini.ReadInteger( 'GRA', 'gracz__2__indeks', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  case zti of
      1 : Gracz__2__Czo�g_Wybrany__Lewo__D�_RadioButton.Checked := true;
      2 : Gracz__2__Czo�g_Wybrany__Prawo__D�_RadioButton.Checked := true;
      3 : Gracz__2__Czo�g_Wybrany__Lewo__G�ra_RadioButton.Checked := true;
      4 : Gracz__2__Czo�g_Wybrany__Prawo__G�ra_RadioButton.Checked := true;
      else//case zti of
        Gracz__2__Czo�g_Wybrany__Brak_RadioButton.Checked := true;
    end;
  //---//case zti of


  zts := Boolean_W__Tak_Nie( Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'opcje__rozmiar_zak�adki_zwi�ksz' )  ) then
    plik_ini.WriteString( 'GRA', 'opcje__rozmiar_zak�adki_zwi�ksz', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'opcje__rozmiar_zak�adki_zwi�ksz', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zts := Boolean_W__Tak_Nie( Si_Linie_Bez_Graczy_CheckBox.Checked );

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'si_linie_bez_graczy' )  ) then
    plik_ini.WriteString( 'GRA', 'si_linie_bez_graczy', zts )
  else
    zts := plik_ini.ReadString( 'GRA', 'si_linie_bez_graczy', zts ); // Je�eli nie znajdzie to podstawia warto�� zts.

  Si_Linie_Bez_Graczy_CheckBox.Checked := zts = Boolean_W__Tak_Nie( true );


  zti := Trudno��_Stopie�__Op�nienie__Jazda_SpinEdit.Value;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'trudno��_stopie�__op�nienie__jazda' )  ) then
    plik_ini.WriteInteger( 'GRA', 'trudno��_stopie�__op�nienie__jazda', zti )
  else
    zti := plik_ini.ReadInteger( 'GRA', 'trudno��_stopie�__op�nienie__jazda', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Trudno��_Stopie�__Op�nienie__Jazda_SpinEdit.Value := zti;


  zti := Trudno��_Stopie�__Op�nienie__Strza�_SpinEdit.Value;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'trudno��_stopie�__op�nienie__strza�' )  ) then
    plik_ini.WriteInteger( 'GRA', 'trudno��_stopie�__op�nienie__strza�', zti )
  else
    zti := plik_ini.ReadInteger( 'GRA', 'trudno��_stopie�__op�nienie__strza�', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Trudno��_Stopie�__Op�nienie__Strza�_SpinEdit.Value := zti;


  zti := Wiatr_Si�a_SpinEdit.Value;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'GRA', 'wiatr_si�a' )  ) then
    plik_ini.WriteInteger( 'GRA', 'wiatr_si�a', zti )
  else
    zti := plik_ini.ReadInteger( 'GRA', 'wiatr_si�a', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Wiatr_Si�a_SpinEdit.Value := zti;
  {$endregion 'GRA.'}

  {$region 'KLAWIATURA_KONFIGURACJA.'}
  zti := Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__amunicja_pr�dko��__minus' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__amunicja_pr�dko��__minus', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__amunicja_pr�dko��__minus', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Edit.Tag := zti;
  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Edit.Tag );


  zti := Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__amunicja_pr�dko��__plus' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__amunicja_pr�dko��__plus', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__amunicja_pr�dko��__plus', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Edit.Tag := zti;
  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Edit.Tag );


  zti := Klawiatura__Gracz__1__Jed�_Lewo_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__jed�_lewo' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__jed�_lewo', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__jed�_lewo', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__1__Jed�_Lewo_Edit.Tag := zti;
  Klawiatura__Gracz__1__Jed�_Lewo_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__1__Jed�_Lewo_Edit.Tag );


  zti := Klawiatura__Gracz__1__Jed�_Prawo_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__jed�_prawo' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__jed�_prawo', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__jed�_prawo', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__1__Jed�_Prawo_Edit.Tag := zti;
  Klawiatura__Gracz__1__Jed�_Prawo_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__1__Jed�_Prawo_Edit.Tag );


  zti := Klawiatura__Gracz__1__Lufa_D�_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__lufa_d�' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__lufa_d�', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__lufa_d�', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__1__Lufa_D�_Edit.Tag := zti;
  Klawiatura__Gracz__1__Lufa_D�_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__1__Lufa_D�_Edit.Tag );


  zti := Klawiatura__Gracz__1__Lufa_G�ra_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__lufa_g�ra' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__lufa_g�ra', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__lufa_g�ra', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__1__Lufa_G�ra_Edit.Tag := zti;
  Klawiatura__Gracz__1__Lufa_G�ra_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__1__Lufa_G�ra_Edit.Tag );


  zti := Klawiatura__Gracz__1__Strza�_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__strza�' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__strza�', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__1__strza�', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__1__Strza�_Edit.Tag := zti;
  Klawiatura__Gracz__1__Strza�_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__1__Strza�_Edit.Tag );


  zti := Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__amunicja_pr�dko��__minus' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__amunicja_pr�dko��__minus', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__amunicja_pr�dko��__minus', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Edit.Tag := zti;
  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Edit.Tag );


  zti := Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__amunicja_pr�dko��__plus' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__amunicja_pr�dko��__plus', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__amunicja_pr�dko��__plus', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Edit.Tag := zti;
  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Edit.Tag );


  zti := Klawiatura__Gracz__2__Jed�_Lewo_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__jed�_lewo' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__jed�_lewo', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__jed�_lewo', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__2__Jed�_Lewo_Edit.Tag := zti;
  Klawiatura__Gracz__2__Jed�_Lewo_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__2__Jed�_Lewo_Edit.Tag );


  zti := Klawiatura__Gracz__2__Jed�_Prawo_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__jed�_prawo' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__jed�_prawo', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__jed�_prawo', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__2__Jed�_Prawo_Edit.Tag := zti;
  Klawiatura__Gracz__2__Jed�_Prawo_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__2__Jed�_Prawo_Edit.Tag );


  zti := Klawiatura__Gracz__2__Lufa_D�_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__lufa_d�' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__lufa_d�', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__lufa_d�', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__2__Lufa_D�_Edit.Tag := zti;
  Klawiatura__Gracz__2__Lufa_D�_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__2__Lufa_D�_Edit.Tag );


  zti := Klawiatura__Gracz__2__Lufa_G�ra_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__lufa_g�ra' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__lufa_g�ra', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__lufa_g�ra', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__2__Lufa_G�ra_Edit.Tag := zti;
  Klawiatura__Gracz__2__Lufa_G�ra_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__2__Lufa_G�ra_Edit.Tag );


  zti := Klawiatura__Gracz__2__Strza�_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__strza�' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__strza�', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'gracz__2__strza�', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gracz__2__Strza�_Edit.Tag := zti;
  Klawiatura__Gracz__2__Strza�_Edit.Text := Nazwa_Klawisza( Klawiatura__Gracz__2__Strza�_Edit.Tag );


  zti := Klawiatura__Kamera__D�_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__d�' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__d�', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__d�', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__D�_Edit.Tag := zti;
  Klawiatura__Kamera__D�_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__D�_Edit.Tag );


  zti := Klawiatura__Kamera__G�ra_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__g�ra' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__g�ra', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__g�ra', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__G�ra_Edit.Tag := zti;
  Klawiatura__Kamera__G�ra_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__G�ra_Edit.Tag );


  zti := Klawiatura__Kamera__Lewo_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__lewo' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__lewo', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__lewo', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__Lewo_Edit.Tag := zti;
  Klawiatura__Kamera__Lewo_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__Lewo_Edit.Tag );


  zti := Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__obracanie_mysz�_prze��cz' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__obracanie_mysz�_prze��cz', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__obracanie_mysz�_prze��cz', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Edit.Tag := zti;
  Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Edit.Tag );


  zti := Klawiatura__Kamera__Prawo_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__prawo' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__prawo', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__prawo', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__Prawo_Edit.Tag := zti;
  Klawiatura__Kamera__Prawo_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__Prawo_Edit.Tag );


  zti := Klawiatura__Kamera__Przechy�_Lewo_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__przechy�_lewo' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__przechy�_lewo', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__przechy�_lewo', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__Przechy�_Lewo_Edit.Tag := zti;
  Klawiatura__Kamera__Przechy�_Lewo_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__Przechy�_Lewo_Edit.Tag );


  zti := Klawiatura__Kamera__Przechy�_Prawo_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__przechy�_prawo' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__przechy�_prawo', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__przechy�_prawo', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__Przechy�_Prawo_Edit.Tag := zti;
  Klawiatura__Kamera__Przechy�_Prawo_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__Przechy�_Prawo_Edit.Tag );


  zti := Klawiatura__Kamera__Prz�d_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__prz�d' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__prz�d', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__prz�d', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__Prz�d_Edit.Tag := zti;
  Klawiatura__Kamera__Prz�d_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__Prz�d_Edit.Tag );


  zti := Klawiatura__Kamera__Reset_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__reset' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__reset', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__reset', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__Reset_Edit.Tag := zti;
  Klawiatura__Kamera__Reset_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__Reset_Edit.Tag );


  zti := Klawiatura__Kamera__Ty�_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'kamera__ty�' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__ty�', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'kamera__ty�', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Kamera__Ty�_Edit.Tag := zti;
  Klawiatura__Kamera__Ty�_Edit.Text := Nazwa_Klawisza( Klawiatura__Kamera__Ty�_Edit.Tag );


  zti := Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'opcje__wy�wietl_ukryj' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'opcje__wy�wietl_ukryj', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'opcje__wy�wietl_ukryj', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Edit.Tag := zti;
  Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Edit.Text := Nazwa_Klawisza( Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Edit.Tag );


  zti := Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'opcje__zwi�_rozwi�' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'opcje__zwi�_rozwi�', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'opcje__zwi�_rozwi�', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Edit.Tag := zti;
  Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Edit.Text := Nazwa_Klawisza( Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Edit.Tag );


  zti := Klawiatura__Gra__Pauza_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'pauza' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'pauza', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'pauza', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gra__Pauza_Edit.Tag := zti;
  Klawiatura__Gra__Pauza_Edit.Text := Nazwa_Klawisza( Klawiatura__Gra__Pauza_Edit.Tag );


  zti := Klawiatura__Gra__Pe�ny_Ekran_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'pe�ny_ekran' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'pe�ny_ekran', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'pe�ny_ekran', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gra__Pe�ny_Ekran_Edit.Tag := zti;
  Klawiatura__Gra__Pe�ny_Ekran_Edit.Text := Nazwa_Klawisza( Klawiatura__Gra__Pe�ny_Ekran_Edit.Tag );


  zti := Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'wsp�czynnik_pr�dko�ci_gry__1' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'wsp�czynnik_pr�dko�ci_gry__1', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'wsp�czynnik_pr�dko�ci_gry__1', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Edit.Tag := zti;
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Edit.Text := Nazwa_Klawisza( Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Edit.Tag );


  zti := Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'wsp�czynnik_pr�dko�ci_gry__minus' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'wsp�czynnik_pr�dko�ci_gry__minus', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'wsp�czynnik_pr�dko�ci_gry__minus', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Edit.Tag := zti;
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Edit.Text := Nazwa_Klawisza( Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Edit.Tag );


  zti := Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'wsp�czynnik_pr�dko�ci_gry__plus' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'wsp�czynnik_pr�dko�ci_gry__plus', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'wsp�czynnik_pr�dko�ci_gry__plus', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Edit.Tag := zti;
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Edit.Text := Nazwa_Klawisza( Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Edit.Tag );


  zti := Klawiatura__Gra__Wyj�cie_Edit.Tag;

  if   (  zapisuj_ustawienia_f )
    or (  not plik_ini.ValueExists( 'KLAWIATURA_KONFIGURACJA', 'wyj�cie' )  ) then
    plik_ini.WriteInteger( 'KLAWIATURA_KONFIGURACJA', 'wyj�cie', zti )
  else
    zti := plik_ini.ReadInteger( 'KLAWIATURA_KONFIGURACJA', 'wyj�cie', zti ); // Je�eli nie znajdzie to podstawia warto�� zti.

  Klawiatura__Gra__Wyj�cie_Edit.Tag := zti;
  Klawiatura__Gra__Wyj�cie_Edit.Text := Nazwa_Klawisza( Klawiatura__Gra__Wyj�cie_Edit.Tag );
  {$endregion 'KLAWIATURA_KONFIGURACJA.'}

  plik_ini.Free();



  zts := ExtractFilePath( Application.ExeName ) + 'T�umaczenia';

  if not DirectoryExists( zts ) then
    begin

      Komunikat_Wy�wietl( 'Nie odnaleziono katalogu t�umacze�' + #13 + #13 + zts + #13 +'.', 'Informacja', MB_ICONEXCLAMATION );

    end
  else//if not DirectoryExists( zts ) then
    begin

      tekst_string_list := TStringList.Create();

      zts := ExtractFilePath( Application.ExeName ) + 'T�umaczenia\T�umaczenia.ini';

      if   (  zapisuj_ustawienia_f )
        or (  not FileExists( zts )  ) then
        begin

          if    ( T�umaczenia_ComboBox.ItemIndex >= 0 )
            and ( T�umaczenia_ComboBox.ItemIndex <= T�umaczenia_ComboBox.Items.Count - 1 ) then
            tekst_string_list.Text := T�umaczenia_ComboBox.Items[ T�umaczenia_ComboBox.ItemIndex ];

          if Trim( tekst_string_list.Text ) = '' then
            tekst_string_list.Text := '<' + t�umaczenie_komunikaty_r.komunikat__domy�lne + '>';

          tekst_string_list.SaveToFile( zts, TEncoding.UTF8 );

        end
      else//if   (  zapisuj_ustawienia_f ) (...)
        begin

          tekst_string_list.LoadFromFile( zts );
          zts := tekst_string_list.Text;
          zts := StringReplace( zts, #$D#$A, '', [ rfReplaceAll ] );

          for zti := T�umaczenia_ComboBox.Items.Count - 1 downto 0 do
            if T�umaczenia_ComboBox.Items[ zti ] = zts then
              begin

                T�umaczenia_ComboBox.ItemIndex := zti;
                Break;

              end;
            //---//if T�umaczenia_ComboBox.Items[ zti ] = zts then

        end;
      //---//if   (  zapisuj_ustawienia_f ) (...)

      FreeAndNil( tekst_string_list );

    end;
  //---//if not DirectoryExists( zts ) then


  Klawiatura_Konfiguracja__Niepowtarzalno��_Sprawd�();

end;//---//Funkcja Ustawienia_Plik().

//Funkcja Komunikat_Wy�wietl().
function TCzolgi_Form.Komunikat_Wy�wietl( const text_f, caption_f : string; const flags_f : integer ) : integer;
var
  czy_pauza_l,
  gl_user_interface__mouse_look_active
    : boolean;
begin

  czy_pauza_l := Pauza__Sprawd�();
  gl_user_interface__mouse_look_active := GLUserInterface1.MouseLookActive;


  if not czy_pauza_l then
    Pauza_ButtonClick( nil );

  if GLUserInterface1.MouseLookActive then
    GLUserInterface1.MouseLookActive := false;


  Result := Application.MessageBox( PChar(text_f), PChar(caption_f), flags_f );


  if not czy_pauza_l then
    Pauza_ButtonClick( nil );

  if gl_user_interface__mouse_look_active then
    GLUserInterface1.MouseLookActive := true;

end;//---//Funkcja Komunikat_Wy�wietl().

//Funkcja Informacja_Dodatkowa__Ustaw().
procedure TCzolgi_Form.Informacja_Dodatkowa__Ustaw( const napis_f : string = '' );
var
  zti : integer;
  zts : string;
begin

  if not Pauza__Sprawd�() then
    begin

      // Nie pauza.

      Punkty__Separator_GLHUDText.Text := '|';

    end
  else//if not Pauza__Sprawd�() then
    begin

      // Pauza.

      Punkty__Separator_GLHUDText.Text :=
        '|' +
        #13 +
        t�umaczenie_komunikaty_r.ekran_napis__pauza;

    end;
  //---//if not Pauza__Sprawd�() then


  if Trim( napis_f ) <> '' then
    begin

      informacja_dodatkowa_g := napis_f;
      informacja_dodatkowa_wy�wietlenie_g := Now();

    end;
  //---//if Trim( napis_f ) <> '' then


  if Trim( informacja_dodatkowa_g ) <> '' then
    Punkty__Separator_GLHUDText.Text := Punkty__Separator_GLHUDText.Text +
    #13 +
    informacja_dodatkowa_g;



  zti := 1;
  zts := Punkty__Separator_GLHUDText.Text;

  while Pos( #13, zts ) > 0 do
    begin

      inc( zti );
      zts := StringReplace( zts, #13, '', [] );

    end;
  //---//while Pos( #13, zts ) > 0 do


  Punkty__Lewo__GLHUDSprite.Height := Gracz__1__GLHUDSprite.Height * zti;
  Punkty__Prawo__GLHUDSprite.Height := Punkty__Lewo__GLHUDSprite.Height;

  Punkty__Lewo__GLHUDSprite.Position.Y := Punkty__Lewo__GLHUDSprite.Height * 0.5 + 5;
  Punkty__Prawo__GLHUDSprite.Position.Y := Punkty__Lewo__GLHUDSprite.Position.Y;

  GLWindowsBitmapFont1.EnsureString( Punkty__Separator_GLHUDText.Text );

end;//---//Funkcja Informacja_Dodatkowa__Ustaw().

//Funkcja Informacja_Dodatkowa__Wa�no��_Sprawd�().
procedure TCzolgi_Form.Informacja_Dodatkowa__Wa�no��_Sprawd�();
begin

  if    (  Trim( informacja_dodatkowa_g ) <> ''  )
    and (  SecondsBetween( Now(), informacja_dodatkowa_wy�wietlenie_g ) > 5  ) then
    begin

      informacja_dodatkowa_g := '';
      Informacja_Dodatkowa__Ustaw();

    end;
  //---//if    (  Trim( informacja_dodatkowa_g ) <> ''  ) (...)

end;//---//Funkcja Informacja_Dodatkowa__Wa�no��_Sprawd�().

//Funkcja SI_Decyduj().
procedure TCzolgi_Form.SI_Decyduj( const delta_czasu_f : double );
var
  i,
  j,
  zti,
  czo�g_cel_indeks_l
    : integer;
  cel_x,
  czo�g_celownik_x,
  czo�g_jazda_zakres_do_l
    : single;
  prezenty_x_t : array of single;
begin

  for i := 1 to Length( czo�gi_t ) do
    if    ( czo�gi_t[ i ] <> nil )
      and ( czo�gi_t[ i ].si_decyduje )
      and ( czo�gi_t[ i ].Visible ) then
      begin

        if    ( i mod 2 <> 0 ) // Nieparzyste.
          and (  i < Length( czo�gi_t )  ) then
          czo�g_cel_indeks_l := i + 1
        else//if    ( i mod 2 <> 0 ) (...)
        if    ( i mod 2 = 0 ) // Parzyste.
          and ( i > 1 ) then
          czo�g_cel_indeks_l := i - 1
        else//if    ( i mod 2 = 0 ) (...)
          czo�g_cel_indeks_l := -99;

        if czo�g_cel_indeks_l <> -99 then
          cel_x := czo�gi_t[ czo�g_cel_indeks_l ].AbsolutePosition.X
        else//if czo�g_cel_indeks_l <> -99 then
          cel_x := 0;


        czo�g_celownik_x := czo�gi_t[ i ].LocalToAbsolute(  GLS.VectorGeometry.AffineVectorMake(  czo�gi_t[ i ].celownicza_linia.Nodes[ 1 ].X, czo�gi_t[ i ].celownicza_linia.Nodes[ 1 ].Y, czo�gi_t[ i ].celownicza_linia.Nodes[ 1 ].Z  )  ).X;


        {$region 'Obs�uga jako cel prezent�w.'}
        if czo�gi_t[ i ].si__prezent_cel_x <> null then
          begin

            // Sprawdza czy wybrany jako cel prezent jeszcze istnieje (lub inny w tym samym miejscu).

            zti := 0;

            for j := 0 to prezenty_list.Count - 1 do
              if    ( not TPrezent(prezenty_list[ j ]).czy_prezent_zebrany )
                and ( czo�gi_t[ i ].si__prezent_cel_x = TPrezent(prezenty_list[ j ]).Position.X )
                //and ( TPrezent(prezenty_list[ j ]).Position.Z = czo�gi_t[ i ].Position.Z ) // Z jakiego� wzgl�du czo�g 2 ma wsp�rz�dn� Z r�n� od 0 (e do pot�gi minus).
                and (  Round( TPrezent(prezenty_list[ j ]).Position.Z ) = Round( czo�gi_t[ i ].Position.Z )  ) then
                begin

                  zti := 1;
                  Break;

                end;
              //---//if    ( not TPrezent(prezenty_list[ j ]).czy_prezent_zebrany ) (...)

            if zti <> 1 then
              czo�gi_t[ i ].si__prezent_cel_x := null; // Nie ma ju� prezentu.

          end
        else//if czo�gi_t[ i ].si__prezent_cel_x <> null then
          if Czas_Mi�dzy_W_Sekundach( czo�gi_t[ i ].si__prezent_cel__wyznaczenie_sekundy_czas_i ) > si__prezent_cel__wyznaczenie_kolejne_sekundy_c then
            begin

              // Tworzy list� prezent�w do ustawienia jako cel.
              SetLength( prezenty_x_t, 0 );

              for j := 0 to prezenty_list.Count - 1 do
                if    ( not TPrezent(prezenty_list[ j ]).czy_prezent_zebrany )
                  //and ( TPrezent(prezenty_list[ j ]).Position.Z = czo�gi_t[ i ].Position.Z ) // Z jakiego� wzgl�du czo�g 2 ma wsp�rz�dn� Z r�n� od 0 (e do pot�gi minus).
                  and (  Round( TPrezent(prezenty_list[ j ]).Position.Z ) = Round( czo�gi_t[ i ].Position.Z )  ) then
                  begin


                    zti := Length( prezenty_x_t );
                    SetLength( prezenty_x_t, zti + 1 );
                    prezenty_x_t[ zti ] := TPrezent(prezenty_list[ j ]).Position.X;

                    //cel_x := TPrezent(prezenty_list[ j ]).Position.X;
                    //Break;

                  end;
                //---//if    ( not TPrezent(prezenty_list[ j ]).czy_prezent_zebrany ) (...)


              if Length( prezenty_x_t ) > 0 then
                begin

                  // Istniej� prezenty do ustawienia jako cel.

                  zti := 35; // Domy�lna szansa na wycelowanie w prezent.

                  // Posiadanie bonus�w z prezent�w obni�a szans� na wycelowanie w prezent.
                  if czo�gi_t[ i ].bonus__jazda_szybsza__zdobycie_sekundy_czas_i <> 0 then
                    zti := zti - 10;

                  if czo�gi_t[ i ].bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i <> 0 then
                    zti := zti - 10;
                  //---// Posiadanie bonus�w z prezent�w obni�a szans� na wycelowanie w prezent.


                  // Je�eli cel jest poza zasi�giem wzrasta szansa na wycelowanie w prezent.
                  if    (  Abs( cel_x ) > 25  )
                    and (  Abs( czo�g_celownik_x - cel_x ) > 5  )
                    and ( czo�gi_t[ i ].amunicja_pr�dko��_ustawiona > amunicja_pr�dko��_ustawiona__maksymalna_c - amunicja_pr�dko��_ustawiona__maksymalna_c * 0.1 )
                    and (  Abs( czo�gi_t[ i ].si__lufa_uniesienie_k�t - 45 ) <= 5  ) then
                    zti := zti + 50;

                  if Random( 100 ) + 1 <= zti then
                    czo�gi_t[ i ].si__prezent_cel_x := prezenty_x_t[ Random(  Length( prezenty_x_t )  ) ];

                end;
              //---//if Length( prezenty_x_t ) > 0 then

              SetLength( prezenty_x_t, 0 );


              czo�gi_t[ i ].si__prezent_cel__wyznaczenie_sekundy_czas_i := Czas_Teraz_W_Sekundach();

            end;
          //---//if Czas_Mi�dzy_W_Sekundach( czo�gi_t[ i ].si__prezent_cel__wyznaczenie_sekundy_czas_i ) > si__prezent_cel__wyznaczenie_kolejne_sekundy_c then
        {$endregion 'Obs�uga jako cel prezent�w.'}


        if czo�gi_t[ i ].si__prezent_cel_x <> null then
          cel_x := czo�gi_t[ i ].si__prezent_cel_x;


        {$region 'Jazda.'}
        if   (  Czas_Mi�dzy_W_Sekundach( czo�gi_t[ i ].si__jazda_cel__wyznaczenie_sekundy_czas_i ) > czo�gi_t[ i ].si__jazda_cel__wyznaczenie_kolejne_sekundy_czas + Trudno��_Stopie�__Op�nienie__Jazda_SpinEdit.Value  )
          or ( czo�gi_t[ i ].si__jazda_cel = 0 ) then // Warto�� pocz�tkowa.
          begin

            // Czo�g sterowany przez SI nie wycofuje si� dalej ni� gracz b�d�cy naprzeciw niego (je�eli gracz nie przekroczy domy�lnego obszaru jazdy).
            if    ( i mod 2 <> 0 ) // Nieparzyste.
              and (  i < Length( czo�gi_t )  )
              and (
                       ( i + 1 = Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                    or (  i + 1 = Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
                  ) then
              czo�g_jazda_zakres_do_l := Abs( czo�gi_t[ i + 1 ].Position.X )
            else//if    ( i mod 2 <> 0 ) (...)
            if    ( i mod 2 = 0 ) // Parzyste.
              and ( i > 1 )
              and (
                       ( i - 1 = Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                    or (  i - 1 = Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
                  ) then
              czo�g_jazda_zakres_do_l := Abs( czo�gi_t[ i - 1 ].Position.X )
            else//if    ( i mod 2 = 0 ) (...)
              czo�g_jazda_zakres_do_l := czo�g_jazda_zakres__do_c;
            //---// Czo�g sterowany przez SI nie wycofuje si� dalej ni� gracz b�d�cy naprzeciw niego (je�eli gracz nie przekroczy domy�lnego obszaru jazdy).


            if    (  Abs( cel_x ) > 25  )
              and (  Abs( czo�g_celownik_x - cel_x ) > 5  )
              and ( czo�gi_t[ i ].amunicja_pr�dko��_ustawiona > amunicja_pr�dko��_ustawiona__maksymalna_c - amunicja_pr�dko��_ustawiona__maksymalna_c * 0.1 )
              and (  Abs( czo�gi_t[ i ].si__lufa_uniesienie_k�t - 45 ) <= 5  ) then
              begin

                // Je�eli cel jest poza zasi�giem np. z powodu wiatru to podje�d�a bli�ej rzeki.

                czo�g_jazda_zakres_do_l := Abs( czo�gi_t[ i ].Position.X );


                if czo�g_jazda_zakres_do_l <= czo�g_jazda_zakres__od_c + 5 then
                  czo�g_jazda_zakres_do_l := czo�g_jazda_zakres__od_c + 20;

              end
            else//if    (  Abs( cel_x ) > 25  ) (...)
              begin

                // Domy�lny obszar jazdy.
                if i <= 2 then
                  begin

                    if czo�g_jazda_zakres_do_l < 45 then
                      czo�g_jazda_zakres_do_l := 45;

                  end
                else//if i <= 2 then
                  begin

                    if czo�g_jazda_zakres_do_l < 120 then
                      czo�g_jazda_zakres_do_l := 120;

                  end;
                //---//if i <= 2 then
                //---// Domy�lny obszar jazdy.


                if czo�g_jazda_zakres_do_l < czo�g_jazda_zakres__od_c then
                  czo�g_jazda_zakres_do_l := czo�g_jazda_zakres__od_c + 1;

              end;
            //---//if    (  Abs( cel_x ) > 25  ) (...)


            //czo�gi_t[ i ].si__jazda_cel := czo�g_jazda_zakres__od_c + Random(  Round( czo�g_jazda_zakres__do_c - czo�g_jazda_zakres__od_c ) + 1  );
            czo�gi_t[ i ].si__jazda_cel :=
                czo�g_jazda_zakres__od_c
              + Random(  Round( czo�g_jazda_zakres_do_l - czo�g_jazda_zakres__od_c ) + 1  ) +
              + Random( 11 ) * 0.1; // U�amkowa cz�� wsp�rz�dnej.


            // Nieparzyste lewo, parzyste prawo.
            if i mod 2 <> 0 then
              czo�gi_t[ i ].si__jazda_cel := -czo�gi_t[ i ].si__jazda_cel;


            czo�gi_t[ i ].si__jazda_cel__wyznaczenie_kolejne_sekundy_czas := Random( si__jazda_cel__wyznaczenie_kolejne__losuj_z_sekundy_c );
            czo�gi_t[ i ].si__jazda_cel__wyznaczenie_sekundy_czas_i := Czas_Teraz_W_Sekundach();

          end;
        //---//if   (  Czas_Mi�dzy_W_Sekundach( czo�gi_t[ i ].si__jazda_cel__wyznaczenie_sekundy_czas_i ) > czo�gi_t[ i ].si__jazda_cel__wyznaczenie_kolejne_sekundy_czas + Trudno��_Stopie�__Op�nienie__Jazda_SpinEdit.Value  ) (...)


        if Abs( czo�gi_t[ i ].Position.X - czo�gi_t[ i ].si__jazda_cel ) > 0.1 then
          begin

            if Abs( czo�gi_t[ i ].si__jazda_cel ) > Abs( czo�gi_t[ i ].Position.X ) then
              czo�gi_t[ i ].Jed�( delta_czasu_f, true )
            else//if czo�gi_t[ i ].si__jazda_cel > czo�gi_t[ i ].Position.X then
              czo�gi_t[ i ].Jed�( delta_czasu_f );

          end;
        //---//if Abs( czo�gi_t[ i ].Position.X - czo�gi_t[ i ].si__jazda_cel ) > 0.1 then
        {$endregion 'Jazda.'}


        {$region 'Celowanie.'}
        if Abs( czo�g_celownik_x - cel_x ) > 0.1 then
          begin

            if Abs( cel_x ) < 40 then
              begin

                //if czo�gi_t[ i ].amunicja_pr�dko��_ustawiona > amunicja_pr�dko��_ustawiona__maksymalna_c * 0.5 then
                //  czo�gi_t[ i ].Amunicja_Pr�dko��_Ustaw( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value, true ); // Lub.

                if czo�gi_t[ i ].si__lufa_uniesienie_k�t < 45 then
                  czo�gi_t[ i ].si__lufa_uniesienie_k�t := 45 // Celowanie w cele blisko do rzeki - uniesienie lufy powy�ej 45 stopni.
                else//if czo�gi_t[ i ].si__lufa_uniesienie_k�t < 45 then
                //if    ( czo�gi_t[ i ].si__lufa_uniesienie_k�t > 45 ) // Lub.
                //  and (
                //           ( // Celuje za blisko.
                //                 ( not czo�gi_t[ i ].amunicja_lot_w_lewo )
                //             and ( czo�g_celownik_x < cel_x )
                //           )
                //        or (
                //                 ( czo�gi_t[ i ].amunicja_lot_w_lewo )
                //             and ( czo�g_celownik_x > cel_x )
                //           )
                //      ) then
                //  czo�gi_t[ i ].si__lufa_uniesienie_k�t := czo�gi_t[ i ].si__lufa_uniesienie_k�t - 1
                //else
                //if    ( czo�gi_t[ i ].si__lufa_uniesienie_k�t < lufa_uniesienie_maksymalne_k�t_c )
                //  and (
                //           ( // Celuje za daleko.
                //                 ( not czo�gi_t[ i ].amunicja_lot_w_lewo )
                //             and ( czo�g_celownik_x > cel_x )
                //           )
                //        or (
                //                 ( czo�gi_t[ i ].amunicja_lot_w_lewo )
                //             and ( czo�g_celownik_x < cel_x )
                //           )
                //      ) then
                //  czo�gi_t[ i ].si__lufa_uniesienie_k�t := czo�gi_t[ i ].si__lufa_uniesienie_k�t + 1;
                if   ( // Celuje za blisko.
                           ( not czo�gi_t[ i ].amunicja_lot_w_lewo )
                       and ( czo�g_celownik_x < cel_x )
                     )
                  or (
                           ( czo�gi_t[ i ].amunicja_lot_w_lewo )
                       and ( czo�g_celownik_x > cel_x )
                     ) then
                  begin

                    // Najpierw obni�a luf�, potem zwi�ksza pr�dko�� amunicji.
                    if czo�gi_t[ i ].si__lufa_uniesienie_k�t > 45 then
                      czo�gi_t[ i ].si__lufa_uniesienie_k�t := czo�gi_t[ i ].si__lufa_uniesienie_k�t - 1
                    else//if czo�gi_t[ i ].si__lufa_uniesienie_k�t > 45 then
                      if czo�gi_t[ i ].amunicja_pr�dko��_ustawiona < amunicja_pr�dko��_ustawiona__maksymalna_c then
                        czo�gi_t[ i ].Amunicja_Pr�dko��_Ustaw( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value );

                  end
                else//if   ( (...)
                  if   ( // Celuje za daleko.
                             ( not czo�gi_t[ i ].amunicja_lot_w_lewo )
                         and ( czo�g_celownik_x > cel_x )
                       )
                    or (
                             ( czo�gi_t[ i ].amunicja_lot_w_lewo )
                         and ( czo�g_celownik_x < cel_x )
                       ) then
                    // Najpierw podnosi luf�, potem zmniejsza pr�dko�� amunicji.
                    if czo�gi_t[ i ].si__lufa_uniesienie_k�t < lufa_uniesienie_maksymalne_k�t_c then
                      czo�gi_t[ i ].si__lufa_uniesienie_k�t := czo�gi_t[ i ].si__lufa_uniesienie_k�t + 1
                    else//if czo�gi_t[ i ].si__lufa_uniesienie_k�t > 10 then
                      czo�gi_t[ i ].Amunicja_Pr�dko��_Ustaw( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value, true );

              end
            else//if Abs( cel_x ) < 40 then
              begin

                if czo�gi_t[ i ].si__lufa_uniesienie_k�t > 45 then
                  czo�gi_t[ i ].si__lufa_uniesienie_k�t := 45 // Celowanie w cele daleko do rzeki - uniesienie lufy poni�ej 45 stopni.
                else//if czo�gi_t[ i ].si__lufa_uniesienie_k�t > 45 then
                  if   ( // Celuje za blisko.
                             ( not czo�gi_t[ i ].amunicja_lot_w_lewo )
                         and ( czo�g_celownik_x < cel_x )
                       )
                    or (
                             ( czo�gi_t[ i ].amunicja_lot_w_lewo )
                         and ( czo�g_celownik_x > cel_x )
                       ) then
                    begin

                      // Najpierw zwi�ksza pr�dko�� amunicji, potem podnosi luf�.
                      if czo�gi_t[ i ].amunicja_pr�dko��_ustawiona < amunicja_pr�dko��_ustawiona__maksymalna_c then
                        czo�gi_t[ i ].Amunicja_Pr�dko��_Ustaw( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value )
                      else//if czo�gi_t[ i ].amunicja_pr�dko��_ustawiona < amunicja_pr�dko��_ustawiona__maksymalna_c then
                        if czo�gi_t[ i ].si__lufa_uniesienie_k�t < 45 then
                          czo�gi_t[ i ].si__lufa_uniesienie_k�t := czo�gi_t[ i ].si__lufa_uniesienie_k�t + 1;

                    end
                  else//if   ( (...)
                    if   ( // Celuje za daleko.
                               ( not czo�gi_t[ i ].amunicja_lot_w_lewo )
                           and ( czo�g_celownik_x > cel_x )
                         )
                      or (
                               ( czo�gi_t[ i ].amunicja_lot_w_lewo )
                           and ( czo�g_celownik_x < cel_x )
                         ) then
                      // Najpierw obni�a luf�, potem zmniejsza pr�dko�� amunicji.
                      if czo�gi_t[ i ].si__lufa_uniesienie_k�t > 10 then
                        czo�gi_t[ i ].si__lufa_uniesienie_k�t := czo�gi_t[ i ].si__lufa_uniesienie_k�t - 1
                      else//if czo�gi_t[ i ].si__lufa_uniesienie_k�t > 10 then
                        czo�gi_t[ i ].Amunicja_Pr�dko��_Ustaw( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value, true );

              end;
            //---//if Abs( czo�g_celownik_x - cel_x ) > 0.1 then

          end;
        //---//if Abs( czo�g_celownik_x - cel_x ) > 0.1 then


        if Abs( czo�gi_t[ i ].lufa_gl_dummy_cube.RollAngle - czo�gi_t[ i ].si__lufa_uniesienie_k�t ) > 0.1 then
          begin

            if czo�gi_t[ i ].lufa_gl_dummy_cube.RollAngle > czo�gi_t[ i ].si__lufa_uniesienie_k�t then
              czo�gi_t[ i ].Lufa__Uno�( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value )
            else//if czo�gi_t[ i ].lufa_gl_dummy_cube.RollAngle > czo�gi_t[ i ].si__lufa_uniesienie_k�t then
              czo�gi_t[ i ].Lufa__Uno�( delta_czasu_f, Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value, true );

          end;
        //---//if Abs( czo�gi_t[ i ].lufa_gl_dummy_cube.RollAngle - czo�gi_t[ i ].si__lufa_uniesienie_k�t ) > 0.1 then
        {$endregion 'Celowanie.'}


        czo�g_celownik_x := czo�gi_t[ i ].LocalToAbsolute(  GLS.VectorGeometry.AffineVectorMake(  czo�gi_t[ i ].celownicza_linia.Nodes[ 1 ].X, czo�gi_t[ i ].celownicza_linia.Nodes[ 1 ].Y, czo�gi_t[ i ].celownicza_linia.Nodes[ 1 ].Z  )  ).X;


        if    (  Abs( czo�g_celownik_x - cel_x ) <= 0.1  )
          and (   Czas_Mi�dzy_W_Milisekundach( czo�gi_t[ i ].si__wiatr_sprawdzenie_ostatnie_milisekundy_czas_i, true ) > 500 + Trudno��_Stopie�__Op�nienie__Strza�_SpinEdit.Value * 1000  ) then
          begin

            if   ( czo�gi_t[ i ].si__wiatr_si�a_aktualna__warto��_poprzednia = wiatr__si�a_aktualna ) // Przed strza�em czeka na ustabilizowanie si� watru.
              or (  Random( 10 ) + 1 <= 3  ) then // Czasami strzela, mimo �e wiatr nie jest stabilny.
              czo�gi_t[ i ].Strza�();

            czo�gi_t[ i ].si__wiatr_si�a_aktualna__warto��_poprzednia := wiatr__si�a_aktualna;

            czo�gi_t[ i ].si__wiatr_sprawdzenie_ostatnie_milisekundy_czas_i := Czas_Teraz_W_Milisekundach();

          end;
        //---//if    (  Abs( czo�g_celownik_x - cel_x ) <= 0.1  ) (...)

      end;
    //---//if    ( czo�gi_t[ i ] <> nil ) (...)

end;//---//Funkcja SI_Decyduj().

//Funkcja Chmury__Dodaj().
procedure TCzolgi_Form.Chmury__Dodaj();
var
  i : integer;
begin

  if Chmury_GLDummyCube.Effects.Count <= 0 then
    with GLS.ParticleFX.GetOrCreateSourcePFX( Chmury_GLDummyCube ) do
      begin

        Manager := Efekt__Chmury_GLPerlinPFXManager;
        ParticleInterval := 0.1;
        EffectScale := 5;

      end;
    //---//with GLS.ParticleFX.GetOrCreateSourcePFX( Chmury_GLDummyCube ) do


  if Chmury_GLDummyCube.Count <= 0 then
    for i := 1 to 50 do
      with TGLDummyCube.Create( Chmury_GLDummyCube ) do
        begin

          Parent := Chmury_GLDummyCube;
          //VisibleAtRunTime := true; //???

          with GLS.ParticleFX.GetOrCreateSourcePFX( Chmury_GLDummyCube.Children[ Chmury_GLDummyCube.Count - 1 ] ) do
            begin

              Manager := Efekt__Chmury_GLPerlinPFXManager;
              ParticleInterval := 0.1;
              EffectScale := 5;

            end;
          //---//with GLS.ParticleFX.GetOrCreateSourcePFX( Chmury_GLDummyCube.Children[ Chmury_GLDummyCube.Count - 1 ] ) do

        end;
      //---//with TGLDummyCube.Create( Chmury_GLDummyCube ) do


  Chmury__Rozmie��_Losowo();

end;//---//Funkcja Chmury__Dodaj().

//Funkcja Chmury__Rozmie��_Losowo().
procedure TCzolgi_Form.Chmury__Rozmie��_Losowo();
var
  i : integer;
begin

  Chmury_GLDummyCube.Position.X := -Wiatr_Si�a_Modyfikacja_O_Ko�ysanie();

  if Czas_Mi�dzy_W_Sekundach( chmury_rozmie��_losowo__wyznaczenie_sekundy_czas_i ) < chmury_rozmie��_losowo__wyznaczenie_kolejne_sekundy_czas then
    Exit;


  for i := 0 to Chmury_GLDummyCube.Count - 1 do
    begin

      Chmury_GLDummyCube.Children[ i ].Position.Y := Random( 150 );
      Chmury_GLDummyCube.Children[ i ].Position.Z := Random( 200 ) - 250;
      Chmury_GLDummyCube.Children[ i ].Position.X := Random( 800 ) - 400;

    end;
  //---//for i := 0 to Chmury_GLDummyCube.Count - 1 do


  chmury_rozmie��_losowo__wyznaczenie_kolejne_sekundy_czas := Random( 4 ); //3 + Random( 11 ) //???
  chmury_rozmie��_losowo__wyznaczenie_sekundy_czas_i := Czas_Teraz_W_Sekundach();

end;//---//Funkcja Chmury__Rozmie��_Losowo().

//Funkcja Chmury__Usu�().
procedure TCzolgi_Form.Chmury__Usu�();
var
  i : integer;
begin

  for i := Chmury_GLDummyCube.Count - 1 downto 0 do
    Chmury_GLDummyCube.Children[ i ].Free();


  if Chmury_GLDummyCube.Effects.Count > 0 then
    Chmury_GLDummyCube.Effects.Clear();

end;//---//Funkcja Chmury__Usu�().

//Funkcja T�umaczenie__Lista_Wczytaj().
procedure TCzolgi_Form.T�umaczenie__Lista_Wczytaj();
var
  i : integer;
  zts,
  t�umaczenie_nazwa_kopia_l
    : string;
  search_rec : TSearchRec;
begin

  t�umaczenie_nazwa_kopia_l := T�umaczenia_ComboBox.Text;
  T�umaczenia_ComboBox.Items.Clear();
  T�umaczenia_ComboBox.Items.Add( '<' + t�umaczenie_komunikaty_r.komunikat__domy�lne + '>' );
  T�umaczenia_ComboBox.ItemIndex := 0;

  // Je�eli znajdzie plik zwraca 0, je�eli nie znajdzie zwraca numer b��du. Na pocz�tku znajduje '.' '..' potem list� plik�w.
  if FindFirst(  ExtractFilePath( Vcl.Forms.Application.ExeName ) + 'T�umaczenia\*.txt', faAnyFile, search_rec  ) = 0 then
    begin

      repeat

        // Dodaje nazwy plik�w bez rozszerzenia.

        zts := search_rec.Name;
        zts := System.StrUtils.ReverseString( zts );
        Delete(  zts, 1, Pos( '.', zts )  );
        zts := System.StrUtils.ReverseString( zts );

        T�umaczenia_ComboBox.Items.Add( zts );

      until FindNext( search_rec ) <> 0

    end;
  //---//if FindFirst(  ExtractFilePath( Vcl.Forms.Application.ExeName ) + 'T�umaczenia\*.txt', faAnyFile, search_rec  ) = 0 then

  FindClose( search_rec );

  if Trim( t�umaczenie_nazwa_kopia_l ) <> '' then
    for i := T�umaczenia_ComboBox.Items.Count - 1 downto 0 do
      if   ( T�umaczenia_ComboBox.Items[ i ] = t�umaczenie_nazwa_kopia_l )
        or (
                 (  Pos( '<', t�umaczenie_nazwa_kopia_l ) > 0  )
             and (  Pos( '<', T�umaczenia_ComboBox.Items[ i ] ) > 0  )
           ) then
        begin

          T�umaczenia_ComboBox.ItemIndex := i;
          Break;

        end;
      //---//if T�umaczenia_ComboBox.Items[ i ] = zts then

end;//---//Funkcja T�umaczenie__Lista_Wczytaj().

//Funkcja T�umaczenie__Wczytaj().
procedure TCzolgi_Form.T�umaczenie__Wczytaj();
const
  t�umaczenie_komunikaty_r_c_l : string = 't�umaczenie_komunikaty_r.';
  t�umaczenie__nowa_linia_c_l : string = '#13#10';
  t�umaczenie__wyr�nik__elementy_c_l : string = '-->Elementy';
  t�umaczenie__wyr�nik__podpowied�_c_l : string = '-->Podpowied�';

var
  czy_elementy, // Czy t�umaczenie dotyczy element�w komponentu (np. pozycje listy rozwijanej).
  czy_podpowied� // Czy t�umaczenie dotyczy podpowiedzi komponentu.
    : boolean;

  i,
  zti_1,
  zti_2
    : integer;

  zts_1,
  zts_2,
  nazwa
    : string;

  rtti_field : TRttiField;
  rtti_type : TRttiType;

  tekst_l : TStringList;
  zt_component : TComponent;
begin

  if    ( T�umaczenia_ComboBox.ItemIndex >= 0 )
    and ( T�umaczenia_ComboBox.ItemIndex <= T�umaczenia_ComboBox.Items.Count - 1 ) then
    zts_1 := T�umaczenia_ComboBox.Items[ T�umaczenia_ComboBox.ItemIndex ]
  else//if    ( T�umaczenia_ComboBox.ItemIndex >= 0 ) (...)
    zts_1 := '';

  zts_1 := ExtractFilePath( Application.ExeName ) + 'T�umaczenia\' + zts_1 + '.txt';

  if not FileExists( zts_1 ) then
    begin

      T�umaczenie__Domy�lne();

      if Pos( '<', zts_1 ) <= 0 then // Nie wy�wietla komunikatu gdy wybrane jest t�umaczenie '<domy�lne>'.
        Komunikat_Wy�wietl( t�umaczenie_komunikaty_r.komunikat__nie_odnaleziono_pliku_t�umaczenia + #13 + #13 + zts_1 + #13 + '.', t�umaczenie_komunikaty_r.komunikat__b��d, MB_ICONEXCLAMATION + MB_OK );

      Exit;

    end;
  //---//if not FileExists( zts_1 ) then

  Screen.Cursor := crHourGlass;

  tekst_l := TStringList.Create();
  tekst_l.LoadFromFile( zts_1 ); // Je�eli pliku nie ma to nie trzeba wczytywa�, mo�na od razu dodawa� linie.

  if tekst_l.Count > 0 then //???
    rtti_type := TRTTIContext.Create.GetType(  TypeInfo( TT�umaczenie_Komunikaty_r )  );


  for i := 0 to tekst_l.Count - 1 do
    begin

      zts_1 := tekst_l[ i ];

      if Trim( zts_1 ) <> '' then
        begin

          zti_1 := Pos( '=', zts_1 );

          // Te pozycje menu nie podlegaj� t�umaczeniu.
          if   (  Pos( 'Uk�ady_Kostek__Uk�ad_Kostek_', zts_1 ) > 0  )
            or (  Pos( 'Obrazki_Kostek__Obrazek_Kostek_', zts_1 ) > 0  )
            or (
                     (  Pos( 'T�umaczenia_Panel', zts_1 ) > 0  ) // Etykieta panelu t�umaczenia nie podlega t�umaczeniu.
                 and (  Pos( t�umaczenie__wyr�nik__podpowied�_c_l + '=', zts_1 ) <= 0  )

               ) then
            zti_1 := -1;

          // Komentarze '**(...)', '    **(...)'.
          zts_2 := Trim( zts_1 );

          if    ( Length( zts_2 ) > 1 )
            and ( zts_2[ 1 ] = '*' )
            and ( zts_2[ 2 ] = '*' ) then
            zti_1 := -1;

          if zti_1 > 1 then
            begin

              if Pos( t�umaczenie_komunikaty_r_c_l, zts_1 ) <= 0 then
                begin

                  {$region 'Komponenty.'}
                  if Pos( t�umaczenie__wyr�nik__podpowied�_c_l + '=', zts_1 ) > 0 then
                    begin

                      czy_podpowied� := true;
                      zts_1 := StringReplace( zts_1, t�umaczenie__wyr�nik__podpowied�_c_l , '', [] );
                      zti_1 := Pos( '=', zts_1 );

                    end
                  else//if Pos( t�umaczenie__wyr�nik__podpowied�_c_l + '=', zts_1 ) > 0 then
                    czy_podpowied� := false;

                  if Pos( t�umaczenie__wyr�nik__elementy_c_l + '=', zts_1 ) > 0 then
                    begin

                      czy_elementy := true;
                      zts_1 := StringReplace( zts_1, t�umaczenie__wyr�nik__elementy_c_l, '', [] );
                      zti_1 := Pos( '=', zts_1 );

                    end
                  else//if Pos( t�umaczenie__wyr�nik__elementy_c_l + '=', zts_1 ) > 0 then
                    czy_elementy := false;


                  nazwa := Copy( zts_1, 1, zti_1 - 1 );
                  Delete( zts_1, 1, zti_1 );

                  zt_component := nil;

                  zt_component := Self.FindComponent( nazwa );


                  //if czy_podpowied� then //???
                  //  begin
                  //
                  //    // Te podpowiedzi pozycji menu nie podlegaj� t�umaczeniu.
                  //    if   (  Pos( 'Obrazki_Kostek__Domy�lne_MenuItem', nazwa ) > 0  )
                  //      or (  Pos( 'Obrazki_Kostek__Brak_MenuItem', nazwa ) > 0  ) then
                  //      zt_component := nil;
                  //
                  //  end;
                  ////---//if czy_podpowied� then


                  if zt_component <> nil then
                    begin

                      zts_1 := StringReplace( zts_1, t�umaczenie__nowa_linia_c_l, #13 + #10, [ rfReplaceAll ] );

                      if Pos( '_BitBtn', nazwa ) > 0 then
                        begin

                          if not czy_podpowied� then
                            TBitBtn(zt_component).Caption := zts_1
                          else//if not czy_podpowied� then
                            TBitBtn(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_Button', nazwa ) > 0 then
                        begin

                          if not czy_podpowied� then
                            TButton(zt_component).Caption := zts_1
                          else//if not czy_podpowied� then
                            TButton(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_CheckBox', nazwa ) > 0 then
                        begin

                          if not czy_podpowied� then
                            TCheckBox(zt_component).Caption := zts_1
                          else//if not czy_podpowied� then
                            TCheckBox(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_ComboBox', nazwa ) > 0 then
                        begin

                          if czy_podpowied� then
                            TComboBox(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_Edit', nazwa ) > 0 then
                        begin

                          if czy_podpowied� then
                            TEdit(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_GroupBox', nazwa ) > 0 then
                        begin

                          if not czy_podpowied� then
                            TGroupBox(zt_component).Caption := zts_1
                          else//if not czy_podpowied� then
                            TGroupBox(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_Label', nazwa ) > 0 then
                        begin

                          if not czy_podpowied� then
                            TLabel(zt_component).Caption := zts_1
                          else//if not czy_podpowied� then
                            TLabel(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_RadioButton', nazwa ) > 0 then
                        begin

                          if not czy_podpowied� then
                            TRadioButton(zt_component).Caption := zts_1
                          else//if not czy_podpowied� then
                            TRadioButton(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_RadioGroup', nazwa ) > 0 then
                        begin

                          if not czy_podpowied� then
                            begin

                              if not czy_elementy then
                                TRadioGroup(zt_component).Caption := zts_1
                              else//if not czy_elementy then
                                begin

                                  zti_2 := TRadioGroup(zt_component).ItemIndex;

                                  TRadioGroup(zt_component).Items.Clear();

                                  zti_1 := Pos( ';', zts_1 );

                                  while zti_1 > 0 do
                                    begin

                                      zts_2 := Copy( zts_1, 1, zti_1 - 1 );
                                      Delete( zts_1, 1, zti_1 );

                                      zts_2 := StringReplace( zts_2, #13, '', [ rfReplaceAll ] );

                                      TRadioGroup(zt_component).Items.Add( zts_2 );

                                      zti_1 := Pos( ';', zts_1 );

                                    end;
                                  //---//while zti_1 > 0 do

                                  if    ( zti_2 >= 0 )
                                    and ( zti_2 <= TRadioGroup(zt_component).Items.Count - 1 ) then
                                    TRadioGroup(zt_component).ItemIndex := zti_2;

                                end;
                              //---//if zti_1 <= 0 then

                            end
                          else//if not czy_elementy then
                            TRadioGroup(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_SpinEdit', nazwa ) > 0 then
                        begin

                          if czy_podpowied� then
                            TSpinEdit(zt_component).Hint := zts_1;

                        end
                      else
                      if Pos( '_TabSheet', nazwa ) > 0 then
                        begin

                          if not czy_podpowied� then
                            TTabSheet(zt_component).Caption := zts_1
                          else//if not czy_podpowied� then
                            TTabSheet(zt_component).Hint := zts_1;

                        end
                      else
                        ;

                    end;
                  //---//if zt_component <> nil then
                  {$endregion 'Komponenty.'}

                end
              else//if Pos( t�umaczenie_komunikaty_r_c_l, zts_1 ) <= 0 then
                begin

                  {$region 'Komunikaty.'}
                  nazwa := Copy( zts_1, 1, zti_1 - 1 );
                  Delete( zts_1, 1, zti_1 );

                  nazwa := StringReplace( nazwa, t�umaczenie_komunikaty_r_c_l, '', [ rfReplaceAll ] );
                  zts_1 := StringReplace( zts_1, t�umaczenie__nowa_linia_c_l, #13 + #10, [ rfReplaceAll ] );

                  for rtti_field in rtti_type.GetFields do
                    if rtti_field.Name = nazwa then
                      begin

                        if rtti_field.GetValue( @t�umaczenie_komunikaty_r ).Kind in [ System.TypInfo.tkUString, System.TypInfo.tkString, System.TypInfo.tkWString ] then
                          rtti_field.SetValue( @t�umaczenie_komunikaty_r, zts_1 );

                        Break;

                      end;
                    //---//if rtti_field.Name = nazwa then
                  {$endregion 'Komunikaty.'}

                end;
              //---//if Pos( t�umaczenie_komunikaty_r_c_l, zts_1 ) <= 0 then

            end;
          //---//if zti_1 > 1 then

        end;
      //---//if Trim( zts_1 ) <> '' then

    end;
  //---//for i := 0 to tekst_l.Count - 1 do

  tekst_l.Free();


  T�umaczenie__Lista_Wczytaj(); // Aby zaktualizowa� tre�� t�umaczenie_komunikaty_r.komunikat__domy�lne.

  Interfejs_Wska�niki_Ustaw( true );
  Informacja_Dodatkowa__Ustaw();

  Screen.Cursor := crDefault;

end;//---//Funkcja T�umaczenie__Wczytaj().

//Funkcja T�umaczenie__Domy�lne().
procedure TCzolgi_Form.T�umaczenie__Domy�lne();
var
  zti : integer;
begin

  t�umaczenie_komunikaty_r.ekran_napis__pauza := 'PAUZA';
  t�umaczenie_komunikaty_r.komunikat__b��d := 'B��d';
  t�umaczenie_komunikaty_r.komunikat__czy_wyj��_z_gry := 'Czy wyj�� z gry?';
  t�umaczenie_komunikaty_r.komunikat__domy�lne := 'domy�lne';
  t�umaczenie_komunikaty_r.komunikat__nie_odnaleziono_pliku_t�umaczenia := 'Nie odnaleziono pliku t�umaczenia:';
  t�umaczenie_komunikaty_r.komunikat__pytanie := 'Pytanie';
  t�umaczenie_komunikaty_r.komunikat__wczyta�_ustawienia := 'Wczyta� ustawienia?';
  t�umaczenie_komunikaty_r.komunikat__zapisa�_ustawienia := 'Zapisa� ustawienia?';
  t�umaczenie_komunikaty_r.s�owo__gracz := 'Gracz';
  t�umaczenie_komunikaty_r.s�owo__gracz__skr�t := 'G.';


  Gra_TabSheet.Caption := 'Gra';
  Gra_TabSheet.Hint := '';
  Opcje_TabSheet.Caption := 'Opcje';
  Opcje_TabSheet.Hint := '';
  O_Programie_TabSheet.Caption := 'O programie';
  O_Programie_TabSheet.Hint := '';

  Gracz__1__Czo�g_Wybrany_GroupBox.Caption := 'Gracz';
  Gracz__1__Czo�g_Wybrany_GroupBox.Hint := '';
  Gracz__1__Czo�g_Wybrany__Lewo__G�ra_RadioButton.Caption := 'L g';
  Gracz__1__Czo�g_Wybrany__Lewo__G�ra_RadioButton.Hint := 'Lewo g�ra.';
  Gracz__1__Czo�g_Wybrany__Lewo__D�_RadioButton.Caption := 'L d';
  Gracz__1__Czo�g_Wybrany__Lewo__D�_RadioButton.Hint := 'Lewo d�.';
  Gracz__1__Czo�g_Wybrany__Prawo__G�ra_RadioButton.Caption := 'P g';
  Gracz__1__Czo�g_Wybrany__Prawo__G�ra_RadioButton.Hint := 'Prawo g�ra.';
  Gracz__1__Czo�g_Wybrany__Prawo__D�_RadioButton.Caption := 'P d';
  Gracz__1__Czo�g_Wybrany__Prawo__D�_RadioButton.Hint := 'Prawo d�.';
  Gracz__1__Czo�g_Wybrany__Brak_RadioButton.Caption := '<brak>';
  Gracz__1__Czo�g_Wybrany__Brak_RadioButton.Hint := '';
  Gracz__1__Akceptuje_Si_CheckBox.Caption := 'SI';
  Gracz__1__Akceptuje_Si_CheckBox.Hint := 'Akceptuj gr� przeciwko SI.';
  Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Caption := 'Jednostka pr�dko�ci';
  Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Hint := 'Jednostka pr�dko�ci amunicji.';

    zti := Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex;
    Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Items.Clear();
    Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Items.Add( '%' );
    Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Items.Add( 'm/s' );

    if    ( zti >= 0 )
      and ( zti <= Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Items.Count ) then
      Gracz__1__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex := zti;

  Gracz__2__Czo�g_Wybrany_GroupBox.Caption := 'Gracz';
  Gracz__2__Czo�g_Wybrany_GroupBox.Hint := '';
  Gracz__2__Czo�g_Wybrany__Lewo__G�ra_RadioButton.Caption := 'L g';
  Gracz__2__Czo�g_Wybrany__Lewo__G�ra_RadioButton.Hint := 'Lewo g�ra.';
  Gracz__2__Czo�g_Wybrany__Lewo__D�_RadioButton.Caption := 'L d';
  Gracz__2__Czo�g_Wybrany__Lewo__D�_RadioButton.Hint := 'Lewo d�.';
  Gracz__2__Czo�g_Wybrany__Prawo__G�ra_RadioButton.Caption := 'P g';
  Gracz__2__Czo�g_Wybrany__Prawo__G�ra_RadioButton.Hint := 'Prawo g�ra.';
  Gracz__2__Czo�g_Wybrany__Prawo__D�_RadioButton.Caption := 'P d';
  Gracz__2__Czo�g_Wybrany__Prawo__D�_RadioButton.Hint := 'Prawo d�.';
  Gracz__2__Czo�g_Wybrany__Brak_RadioButton.Caption := '<brak>';
  Gracz__2__Czo�g_Wybrany__Brak_RadioButton.Hint := '';
  Gracz__2__Akceptuje_Si_CheckBox.Caption := 'SI';
  Gracz__2__Akceptuje_Si_CheckBox.Hint := 'Akceptuj gr� przeciwko SI.';
  Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Caption := 'Jednostka pr�dko�ci';
  Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Hint := 'Jednostka pr�dko�ci amunicji.';

    zti := Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex;
    Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Items.Clear();
    Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Items.Add( '%' );
    Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Items.Add( 'm/s' );

    if    ( zti >= 0 )
      and ( zti <= Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.Items.Count ) then
      Gracz__2__Amunicja_Pr�dko��_Ustawiona_Jednostka_RadioGroup.ItemIndex := zti;

  Celownicza_Linia_CheckBox.Caption := 'Celownik';
  Celownicza_Linia_CheckBox.Hint := '';
  Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox.Caption := 'C. korekta o wiatr';
  Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox.Hint := 'Koryguj celownik o si�� wiatru.';

  Wiatr_Si�a_Etykieta_Label.Caption := 'Si�a wiatru';
  Wiatr_Si�a_Etykieta_Label.Hint := 'W jakim zakresie zmienia si� si�a wiatru.';
  Wiatr_Si�a_SpinEdit.Hint := 'W jakim zakresie zmienia si� si�a wiatru.';
  Gra_Wsp�czynnik_Pr�dko�ci_Etykieta_Label.Caption := 'Pr�dko�� gry';
  Gra_Wsp�czynnik_Pr�dko�ci_Etykieta_Label.Hint := '';
  Gra_Wsp�czynnik_Pr�dko�ci_Label.Hint := '';
  Pauza_Button.Caption := 'Pauza';
  Pauza_Button.Hint := '';
  Punkty_Zerowanie_BitBtn.Caption := '0 | 0';
  Punkty_Zerowanie_BitBtn.Hint := 'Wyzeruj uzyskane punkty.';
  Dzie�_Noc_CheckBox.Caption := 'Dzie� noc';
  Dzie�_Noc_CheckBox.Hint := '';
  Godzina_Label.Hint := 'Godzina.';
  Ranek_Label.Caption := 'ranek';
  Ranek_Label.Hint := '';
  Dzie�_Noc__Procent_TrackBar.Hint := '';
  Dzie�_Noc__Czas_Systemowy_Ustaw_CheckBox.Caption := 'Dzie� noc czas systemowy';
  Dzie�_Noc__Czas_Systemowy_Ustaw_CheckBox.Hint := 'Podczas uruchamiania gry ustaw czas w grze wed�ug zegara systemowego.';
  Si_Linie_Bez_Graczy_CheckBox.Caption := 'SI linie bez graczy';
  Si_Linie_Bez_Graczy_CheckBox.Hint := 'SI steruje czo�gami w liniach, w kt�rych nie ma graczy.';
  Trudno��_Stopie�_GroupBox.Caption := 'Stopie� trudno�ci';
  Trudno��_Stopie�_GroupBox.Hint := '';
  Trudno��_Stopie�__Op�nienie__Jazda_Etykieta_Label.Caption := 'Op�nienie jazda [s]';
  Trudno��_Stopie�__Op�nienie__Jazda_Etykieta_Label.Hint := 'Korekta domy�lnego op�nienia mi�dzy kolejnymi decyzjami SI (w sekundach).';
  Trudno��_Stopie�__Op�nienie__Jazda_SpinEdit.Hint := 'Korekta domy�lnego op�nienia mi�dzy kolejnymi decyzjami SI (w sekundach).';
  Trudno��_Stopie�__Op�nienie__Strza�_Etykieta_Label.Caption := 'Op�nienie strza� [s]';
  Trudno��_Stopie�__Op�nienie__Strza�_Etykieta_Label.Hint := 'Korekta domy�lnego op�nienia mi�dzy kolejnymi decyzjami SI (w sekundach).';
  Trudno��_Stopie�__Op�nienie__Strza�_SpinEdit.Hint := 'Korekta domy�lnego op�nienia mi�dzy kolejnymi decyzjami SI (w sekundach).';

  Klawiatura_Konfiguracja_GroupBox.Caption := 'Ustawienia klawiszy';
  Klawiatura_Konfiguracja_GroupBox.Hint := '';
  Klawiatura__Gra_GroupBox.Caption := 'Gra';
  Klawiatura__Gra_GroupBox.Hint := '';
  Klawiatura__Kamera_GroupBox.Caption := 'Kamera';
  Klawiatura__Kamera_GroupBox.Hint := '';
  Klawiatura__Gracz__1_GroupBox.Caption := 'Gracz 1';
  Klawiatura__Gracz__1_GroupBox.Hint := '';
  Klawiatura__Gracz__2_GroupBox.Caption := 'Gracz 2';
  Klawiatura__Gracz__2_GroupBox.Hint := '';

  Celownicza_Linia_Wysoko��_Etykieta_Label.Caption := 'Celownik wysoko�� wska�nika';
  Celownicza_Linia_Wysoko��_Etykieta_Label.Hint := '-1 - wzgl�dem wysoko�ci lotu amunicji;' + #13 + '> -1 - zadana warto��.';
  Celownicza_Linia_Wysoko��_SpinEdit.Hint := '-1 - wzgl�dem wysoko�ci lotu amunicji;' + #13 + '> -1 - zadana warto��.';
  Czo�gi_Linia__3_CheckBox.Caption := 'Czo�gi linia 3';
  Czo�gi_Linia__3_CheckBox.Hint := '';
  Czo�gi_Linia__4_CheckBox.Caption := 'Czo�gi linia 4';
  Czo�gi_Linia__4_CheckBox.Hint := '';
  Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Caption := 'Rozmiar zak�adki zwi�ksz';
  Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Hint := 'Podczas prze��czania zak�adki na opcje zwi�kszaj wysoko�� panelu zak�adek konfiguracji.';

  Efekty_GroupBox.Caption := 'Efekty';
  Efekty_GroupBox.Hint := '';
  Efekty__Chmury_CheckBox.Caption := 'Chmury';
  Efekty__Chmury_CheckBox.Hint := '';
  Efekty__Dym_CheckBox.Caption := 'Dym';
  Efekty__Dym_CheckBox.Hint := 'Dym po trafieniu w ziemi�.';
  Efekty__Lufa_Wystrza�_CheckBox.Caption := 'Wystrza�';
  Efekty__Lufa_Wystrza�_CheckBox.Hint := 'Efekt wystrza�u z lufy.';
  Efekty__Prezent_Zebranie_CheckBox.Caption := 'Prezent';
  Efekty__Prezent_Zebranie_CheckBox.Hint := 'Efekt zebrania prezentu.';
  Efekty__Smuga_CheckBox.Caption := 'Smuga';
  Efekty__Smuga_CheckBox.Hint := 'Smuga za lec�cym pociskiem.';
  Efekty__Trafienie_CheckBox.Caption := 'Trafienie';
  Efekty__Trafienie_CheckBox.Hint := 'Efekt trafienia w czo�g.';
  Efekty__Trafienie__Alternatywny_CheckBox.Caption := 'Traf. al.';
  Efekty__Trafienie__Alternatywny_CheckBox.Hint := 'Alternatywny efekt trafienia w czo�g.';

  T�umaczenie_Etykieta_Label.Caption := 'T�umaczenie';
  T�umaczenie_Etykieta_Label.Hint := '';
  T�umaczenia_ComboBox.Hint := 'Enter - zastosuj.';
  Ustawienia__Wczytaj_BitBtn.Caption := '';
  Ustawienia__Wczytaj_BitBtn.Hint := 'Wczytaj ustawienia.';
  Ustawienia__Zapisz_BitBtn.Caption := '';
  Ustawienia__Zapisz_BitBtn.Hint := 'Zapisz ustawienia.';


  Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Etykieta_Label.Caption := 'Opcje wy�wietl / u.';
  Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Etykieta_Label.Hint := 'Opcje wy�wietl / ukryj.';
  Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Etykieta_Label.Caption := 'Opcje zwi� / roz.';
  Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Etykieta_Label.Hint := 'Opcje zwi� / rozwi�.';
  Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gra__Pauza_Etykieta_Label.Caption := 'Pauza';
  Klawiatura__Gra__Pauza_Etykieta_Label.Hint := '';
  Klawiatura__Gra__Pauza_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gra__Pe�ny_Ekran_Etykieta_Label.Caption := 'Pe�ny ekran';
  Klawiatura__Gra__Pe�ny_Ekran_Etykieta_Label.Hint := '';
  Klawiatura__Gra__Pe�ny_Ekran_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Etykieta_Label.Caption := 'Pr�dko�� gry 1x';
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Etykieta_Label.Hint := '';
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Etykieta_Label.Caption := 'Pr�dko�� gry -';
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Etykieta_Label.Hint := '';
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Etykieta_Label.Caption := 'Pr�dko�� gry +';
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Etykieta_Label.Hint := '';
  Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gra__Wyj�cie_Etykieta_Label.Caption := 'Wyj�cie';
  Klawiatura__Gra__Wyj�cie_Etykieta_Label.Hint := '';
  Klawiatura__Gra__Wyj�cie_Edit.Hint := 'Ctrl + Del - <brak>.';

  Klawiatura__Kamera__D�_Etykieta_Label.Caption := 'D�';
  Klawiatura__Kamera__D�_Etykieta_Label.Hint := '';
  Klawiatura__Kamera__D�_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Kamera__G�ra_Etykieta_Label.Caption := 'G�ra';
  Klawiatura__Kamera__G�ra_Etykieta_Label.Hint := '';
  Klawiatura__Kamera__G�ra_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Kamera__Lewo_Etykieta_Label.Caption := 'Lewo';
  Klawiatura__Kamera__Lewo_Etykieta_Label.Hint := '';
  Klawiatura__Kamera__Lewo_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Etykieta_Label.Caption := 'Obracanie mysz�';
  Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Etykieta_Label.Hint := 'Obracanie mysz� prze��cz.';
  Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Kamera__Prawo_Etykieta_Label.Caption := 'Prawo';
  Klawiatura__Kamera__Prawo_Etykieta_Label.Hint := '';
  Klawiatura__Kamera__Prawo_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Kamera__Przechy�_Lewo_Etykieta_Label.Caption := 'Przechy� lewo';
  Klawiatura__Kamera__Przechy�_Lewo_Etykieta_Label.Hint := '';
  Klawiatura__Kamera__Przechy�_Lewo_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Kamera__Przechy�_Prawo_Etykieta_Label.Caption := 'Przechy� prawo';
  Klawiatura__Kamera__Przechy�_Prawo_Etykieta_Label.Hint := '';
  Klawiatura__Kamera__Przechy�_Prawo_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Kamera__Prz�d_Etykieta_Label.Caption := 'Prz�d';
  Klawiatura__Kamera__Prz�d_Etykieta_Label.Hint := '';
  Klawiatura__Kamera__Prz�d_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Kamera__Reset_Etykieta_Label.Caption := 'Reset';
  Klawiatura__Kamera__Reset_Etykieta_Label.Hint := 'Resetuj pozycj� kamery.';
  Klawiatura__Kamera__Reset_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Kamera__Ty�_Etykieta_Label.Caption := 'Ty�';
  Klawiatura__Kamera__Ty�_Etykieta_Label.Hint := '';
  Klawiatura__Kamera__Ty�_Edit.Hint := 'Ctrl + Del - <brak>.';

  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Etykieta_Label.Caption := 'Amunicja pr�d. -';
  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Etykieta_Label.Hint := 'Amunicja pr�dko�� -.';
  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Minus_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Etykieta_Label.Caption := 'Amunicja pr�d. +';
  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Etykieta_Label.Hint := 'Amunicja pr�dko�� +.';
  Klawiatura__Gracz__1__Amunicja_Pr�dko��__Plus_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__1__Jed�_Lewo_Etykieta_Label.Caption := 'Jed� w lewo';
  Klawiatura__Gracz__1__Jed�_Lewo_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__1__Jed�_Lewo_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__1__Jed�_Prawo_Etykieta_Label.Caption := 'Jed� w prawo';
  Klawiatura__Gracz__1__Jed�_Prawo_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__1__Jed�_Prawo_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__1__Lufa_D�_Etykieta_Label.Caption := 'Lufa w d�';
  Klawiatura__Gracz__1__Lufa_D�_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__1__Lufa_D�_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__1__Lufa_G�ra_Etykieta_Label.Caption := 'Lufa w g�r�';
  Klawiatura__Gracz__1__Lufa_G�ra_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__1__Lufa_G�ra_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__1__Strza�_Etykieta_Label.Caption := 'Strza�';
  Klawiatura__Gracz__1__Strza�_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__1__Strza�_Edit.Hint := 'Ctrl + Del - <brak>.';

  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Etykieta_Label.Caption := 'Amunicja pr�d. -';
  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Etykieta_Label.Hint := 'Amunicja pr�dko�� -.';
  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Minus_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Etykieta_Label.Caption := 'Amunicja pr�d. +';
  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Etykieta_Label.Hint := 'Amunicja pr�dko�� +.';
  Klawiatura__Gracz__2__Amunicja_Pr�dko��__Plus_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__2__Jed�_Lewo_Etykieta_Label.Caption := 'Jed� w lewo';
  Klawiatura__Gracz__2__Jed�_Lewo_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__2__Jed�_Lewo_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__2__Jed�_Prawo_Etykieta_Label.Caption := 'Jed� w prawo';
  Klawiatura__Gracz__2__Jed�_Prawo_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__2__Jed�_Prawo_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__2__Lufa_D�_Etykieta_Label.Caption := 'Lufa w d�';
  Klawiatura__Gracz__2__Lufa_D�_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__2__Lufa_D�_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__2__Lufa_G�ra_Etykieta_Label.Caption := 'Lufa w g�r�';
  Klawiatura__Gracz__2__Lufa_G�ra_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__2__Lufa_G�ra_Edit.Hint := 'Ctrl + Del - <brak>.';
  Klawiatura__Gracz__2__Strza�_Etykieta_Label.Caption := 'Strza�';
  Klawiatura__Gracz__2__Strza�_Etykieta_Label.Hint := '';
  Klawiatura__Gracz__2__Strza�_Edit.Hint := 'Ctrl + Del - <brak>.';


  T�umaczenie__Lista_Wczytaj(); // Aby zaktualizowa� tre�� t�umaczenie_komunikaty_r.komunikat__domy�lne.

  Informacja_Dodatkowa__Ustaw();

end;//---//Funkcja T�umaczenie__Domy�lne().

//Funkcja T�umaczenie__Zastosuj().
procedure TCzolgi_Form.T�umaczenie__Zastosuj();
begin

  if    ( T�umaczenia_ComboBox.ItemIndex >= 0 )
    and ( T�umaczenia_ComboBox.ItemIndex <= T�umaczenia_ComboBox.Items.Count - 1 ) then
    begin

      T�umaczenie__Domy�lne(); // Je�eli w t�umaczeniu czego� zabraknie to zostanie warto�� domy�lna.

      if T�umaczenia_ComboBox.ItemIndex > 0 then
        T�umaczenie__Wczytaj();

    end;
  //---//if    ( T�umaczenia_ComboBox.ItemIndex >= 0 ) (...)

end;//---//Funkcja T�umaczenie__Zastosuj().

//---//      ***      Funkcje      ***      //---//


//FormShow().
procedure TCzolgi_Form.FormShow( Sender: TObject );

  //Funkcja Wa�_Dekoracja_Utw�rz() w FormShow().
  procedure Wa�_Dekoracja_Utw�rz( const i_f : integer; gl_cube_f : TGLCube );
  var
    zt_gl_icosahedron : GLS.GeomObjects.TGLIcosahedron;
  begin

    zt_gl_icosahedron := GLS.GeomObjects.TGLIcosahedron.Create( Gra_GLScene.Objects ); // Zwolni si� razem ze scen�.
    zt_gl_icosahedron.Parent := Gra_GLScene.Objects;
    zt_gl_icosahedron.MoveFirst();

    zt_gl_icosahedron.Scale.X := gl_cube_f.Scale.X + (  Random( 10 ) - 5  ) * 0.1;
    zt_gl_icosahedron.Scale.Y := gl_cube_f.Scale.Y + (  Random( 10 ) - 5  ) * 0.1;
    zt_gl_icosahedron.Scale.Z := gl_cube_f.Scale.X + (  Random( 10 ) - 5  ) * 0.1;

    zt_gl_icosahedron.Position.X := gl_cube_f.Position.X + (  Random( 20 ) - 10  ) * 0.1;

    if gl_cube_f.Position.X < 0 then
      zt_gl_icosahedron.Position.X := zt_gl_icosahedron.Position.X + 0.25
    else//if gl_cube_f.Position.X < 0 then
      zt_gl_icosahedron.Position.X := zt_gl_icosahedron.Position.X - 0.25;

    zt_gl_icosahedron.Position.Y := zt_gl_icosahedron.Scale.Y * 0.25 - Random( 50 ) * 0.01;
    zt_gl_icosahedron.Position.Z := ( gl_cube_f.Scale.Z * 0.5 ) + gl_cube_f.Scale.X * 0.25 - i_f * gl_cube_f.Scale.X * 0.5;

    zt_gl_icosahedron.PitchAngle := Random( 361 );
    zt_gl_icosahedron.RollAngle := Random( 361 );
    zt_gl_icosahedron.TurnAngle := Random( 361 );

    zt_gl_icosahedron.Material.FrontProperties := gl_cube_f.Material.FrontProperties;
    zt_gl_icosahedron.Material.FrontProperties.Ambient.RandomColor();

    if Random( 2 ) = 0 then
      zt_gl_icosahedron.Material.FrontProperties.Diffuse.Color := GLS.Color.clrGreen;

  end;//---//Funkcja Wa�_Dekoracja_Utw�rz() w FormShow().

var
  i : integer;
begin//FormShow().

  sosna := nil;

  kamera_kopia__direction_g := Gra_GLCamera.AbsoluteDirection;
  kamera_kopia__position_g := Gra_GLCamera.AbsolutePosition;
  kamera_kopia__up_g := Gra_GLCamera.AbsoluteUp;


  for i := 1 to Length( czo�gi_t ) do
    czo�gi_t[ i ] := nil;

  SetLength( sosny_gl_proxy_object_t, 0 );


  gra_wsp�czynnik_pr�dko�ci_g := GLCadencer1.TimeMultiplier;
  napis_od�wie�__ostatnie_wywo�anie_g := 0;
  GLCadencer1.CurrentTime := 0;
  GLCadencer1.MaxDeltaTime := 2;

  chmury_rozmie��_losowo__wyznaczenie_sekundy_czas_i := 0;
  chmury_rozmie��_losowo__wyznaczenie_kolejne_sekundy_czas := 0;

  informacja_dodatkowa_g := '';
  informacja_dodatkowa_wy�wietlenie_g := Now();

  noc_zapada := true;
  noc_procent := 0;

  page_control_1_height_pocz�tkowe := PageControl1.Height;

  wiatr__si�a_aktualna := 0;
  wiatr__si�a_docelowa := 0;
  wiatr__zakres := 0;
  wiatr__kolejne_wyliczenie__odliczanie_od_sekundy_czas_i := 0;
  wiatr__kolejne_wyliczenie__za_sekundy_czas_i := 0;

  Randomize();

  Gra_GLSceneViewer.Align := alClient;

  PageControl1.ActivePage := Gra_TabSheet;

  amunicja_wystrzelona_list := TList.Create();
  kratery_list := TList.Create();
  prezenty_list := TList.Create();


  Self.WindowState := wsMaximized;


  T�umaczenie__Domy�lne();
  T�umaczenie__Lista_Wczytaj();

  Ustawienia_Plik();

  T�umaczenie__Wczytaj();


  for i := 1 to Length( czo�gi_t ) do
    begin

      czo�gi_t[ i ] := TCzo�g.Create( Gra_Obiekty_GLDummyCube, GLCollisionManager1, GLCadencer1, Efekty__Lufa_Wystrza�_CheckBox.Checked, Efekty__Trafienie_CheckBox.Checked, Efekty__Trafienie__Alternatywny_CheckBox.Checked );
      czo�gi_t[ i ].Position.X := -30;
      czo�gi_t[ i ].Position.Y := 0.515;

      // Nieparzyste lewo, parzyste prawo.
      if i mod 2 = 0 then
        begin

          czo�gi_t[ i ].Position.X := -Self.czo�gi_t[ i ].Position.X;
          //czo�gi_t[ i ].Turn( 180 );
          czo�gi_t[ i ].TurnAngle := 180;
          czo�gi_t[ i ].amunicja_lot_w_lewo := true;

          czo�gi_t[ i ].Kolor_Ustaw(  GLS.VectorGeometry.VectorMake( 0.25, 0, 0 )  );

        end
      else//if i mod 2 = 0 then
        czo�gi_t[ i ].Kolor_Ustaw(  GLS.VectorGeometry.VectorMake( 0, 0, 0.4 )  );


      //if i > 2 then
      //  czo�gi_t[ i ].Position.Z := -30;
      czo�gi_t[ i ].Position.Z := -30 * (  Ceil( i * 0.5 ) - 1  );

    end;
  //---//for i := 1 to Length( czo�gi_t ) do


  Gracz__2__GLHUDSprite.Height := Gracz__1__GLHUDSprite.Height;

  Punkty__Lewo__GLHUDSprite.Height := Gracz__1__GLHUDSprite.Height;
  Punkty__Lewo__GLHUDSprite.Position.Y := Punkty__Lewo__GLHUDSprite.Height * 0.5 + 5;
  Punkty__Prawo__GLHUDSprite.Height := Punkty__Lewo__GLHUDSprite.Height;
  Punkty__Prawo__GLHUDSprite.Position.Y := Punkty__Lewo__GLHUDSprite.Position.Y;
  Punkty__Prawo__GLHUDSprite.Material.FrontProperties.Diffuse.Color := czo�gi_t[ 2 ].kad�ub.Material.FrontProperties.Emission.Color;
  Punkty__Lewo__GLHUDText.Position.Y := Punkty__Lewo__GLHUDSprite.Position.Y - GLWindowsBitmapFont1.Font.Size; // 15;
  Punkty__Lewo__GLHUDText.Position.Y := Punkty__Lewo__GLHUDText.Position.Y;
  Punkty__Prawo_GLHUDText.Position.Y := Punkty__Lewo__GLHUDText.Position.Y;
  Punkty__Separator_GLHUDText.Position.Y := Punkty__Lewo__GLHUDText.Position.Y;

  Informacja_Dodatkowa__Ustaw();


  // Dynamiczne dodanie zdarzenia kolizji.
  with TGLBCollision.Create( Wa�_Lewo_GLCube.Behaviours ) do
    begin

      GroupIndex := 0;
      BoundingMode := cbmCube;
      Manager := GLCollisionManager1;

    end;
  //---//with TGLBCollision.Create( Wa�_Lewo_GLCube.Behaviours ) do

  // Dynamiczne dodanie zdarzenia kolizji.
  with TGLBCollision.Create( Wa�_Prawo_GLCube.Behaviours ) do
    begin

      GroupIndex := 0;
      BoundingMode := cbmSphere;
      Manager := GLCollisionManager1;

    end;
  //---//with TGLBCollision.Create( Wa�_Prawo_GLCube.Behaviours ) do


  sosna := TSosna.Create( Gra_Obiekty_GLDummyCube );

  Las_Sosnowy_Utw�rz();

  Gra_GLSceneViewer.SetFocus();


  Punkty_Zerowanie_BitBtnClick( Sender );
  Gracz_Czo�g_Wybrany_RadioButtonClick( Gracz__1__Czo�g_Wybrany__Lewo__D�_RadioButton ); // Wed�ug ustawienia pocz�tkowego.

  if Dzie�_Noc__Czas_Systemowy_Ustaw_CheckBox.Checked then
    Dzie�_Noc_Zmie�__Procent_Wed�ug_Czasu_Systemowego_Ustaw()
  else//if Dzie�_Noc__Czas_Systemowy_Ustaw_CheckBox.Checked then
    Dzie�_Noc__Procent_TrackBarChange( Sender );

  kratery_trwanie_poprzednie_sprawdzanie_sekundy_czas_i := Czas_Teraz_W_Sekundach();
  prezenty__kolejne_utworzenie__za_sekundy_czas := prezenty__kolejne_utworzenie__losuj_z_sekundy_c + Random( prezenty__kolejne_utworzenie__losuj_z_sekundy_c );
  prezenty__trwanie_poprzednie_sprawdzanie_sekundy_czas_i := Czas_Teraz_W_Sekundach();
  prezenty__utworzenie_poprzednie_sprawdzanie_sekundy_czas_i := Czas_Teraz_W_Sekundach();


  // Dodaje dekoracje do wa��w.
  for i := 1 to Round( Wa�_Lewo_GLCube.Scale.Z * 0.4 ) do // 1000 / 2.5 = 400.
    begin

      Wa�_Dekoracja_Utw�rz( i, Wa�_Lewo_GLCube );
      Wa�_Dekoracja_Utw�rz( i, Wa�_Prawo_GLCube );

    end;
  //---//for i := 1 to Round( Wa�_Lewo_GLCube.Scale.Z * 0.4 ) do
  //---// Dodaje dekoracje do wa��w.


  if Efekty__Chmury_CheckBox.Checked then
    Efekty__Chmury_CheckBoxClick( Sender );

end;//---//FormShow().

//FormClose().
procedure TCzolgi_Form.FormClose( Sender: TObject; var Action: TCloseAction );
var
  i : integer;
begin

  if Komunikat_Wy�wietl( t�umaczenie_komunikaty_r.komunikat__czy_wyj��_z_gry, t�umaczenie_komunikaty_r.komunikat__pytanie, MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
    begin

      Action := caNone;
      Exit;

    end;
  //---//if Komunikat_Wy�wietl( t�umaczenie_komunikaty_r.komunikat__czy_wyj��_z_gry, t�umaczenie_komunikaty_r.komunikat__pytanie, MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then


  Chmury__Usu�();


  FreeAndNil( sosna );

  for i := 1 to Length( czo�gi_t ) do
    FreeAndNil( czo�gi_t[ i ] );

  Amunicja_Wystrzelona_Zwolnij_Wszystkie();
  FreeAndNil( amunicja_wystrzelona_list );

  Kratery_Zwolnij_Wszystkie();
  FreeAndNil( kratery_list );

  Prezent_Zwolnij_Wszystkie();
  FreeAndNil( prezenty_list );

  for i := 0 to Length( sosny_gl_proxy_object_t ) - 1 do
    FreeAndNil( sosny_gl_proxy_object_t[ i ] );

end;//---//FormClose().

//FormResize().
procedure TCzolgi_Form.FormResize( Sender: TObject );
begin

  Interfejs_Wska�niki_Ustaw( true );

end;//---//FormResize().

//GLCadencer1Progress().
procedure TCzolgi_Form.GLCadencer1Progress( Sender: TObject; const deltaTime, newTime: Double );
begin

  GLCollisionManager1.CheckCollisions();

  if Gra_GLSceneViewer.Focused then
    begin

      GLUserInterface1.MouseLook();
      GLUserInterface1.MouseUpdate();
      Gra_GLSceneViewer.Invalidate();

    end;
  //---//if Gra_GLSceneViewer.Focused then

  Amunicja_Ruch( deltaTime );

  Czo�gi_Parametry_Aktualizuj();

  Kratery_Trwanie_Czas_Sprawd�();

  Prezent_Utw�rz_Jeden();
  //Prezent_Zebranie_Efekt_Animuj( deltaTime );
  Prezent_Trwanie_Czas_Sprawd�();

  if Gra_GLSceneViewer.Focused then
    begin

      Kamera_Ruch( deltaTime );

      Klawisze_Obs�uga_Zachowanie_Ci�g�e( deltaTime );

    end;
  //---//if Gra_GLSceneViewer.Focused then

  Interfejs_Wska�niki_Ustaw();


  Wiatr_Si�a_Wylicz( deltaTime );
  Wiatr_Si�a_Modyfikacja_O_Ko�ysanie();


  if sosna <> nil then
    sosna.Ko�ysanie( deltaTime, wiatr__si�a_aktualna );


  Dzie�_Noc_Zmie�( deltaTime );


  Informacja_Dodatkowa__Wa�no��_Sprawd�();


  SI_Decyduj( deltaTime );


  Chmury__Rozmie��_Losowo();

end;//---//GLCadencer1Progress().

//Gra_GLSceneViewerClick().
procedure TCzolgi_Form.Gra_GLSceneViewerClick( Sender: TObject );
begin

  Gra_GLSceneViewer.SetFocus();

end;//---//Gra_GLSceneViewerClick().

//Gra_GLSceneViewerMouseMove().
procedure TCzolgi_Form.Gra_GLSceneViewerMouseMove( Sender: TObject; Shift: TShiftState; X, Y: Integer );
begin

  if    ( not GLCadencer1.Enabled )
    and ( Self.Active )
    and ( Gra_GLSceneViewer.Focused ) then
    begin

      GLUserInterface1.MouseLook();
      GLUserInterface1.MouseUpdate();
      Gra_GLSceneViewer.Invalidate();

    end;
  //---//if    ( not GLCadencer1.Enabled ) (...)

end;//---//Gra_GLSceneViewerMouseMove().

//Gra_GLSceneViewerKeyDown().
procedure TCzolgi_Form.Gra_GLSceneViewerKeyDown( Sender: TObject; var Key: Word; Shift: TShiftState );
begin

  if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Wyj�cie_Edit.Tag ) then
    Close();


  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__Obracanie_Mysz�_Prze��cz_Edit.Tag ) then
    GLUserInterface1.MouseLookActive := not GLUserInterface1.MouseLookActive;


  if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Pe�ny_Ekran_Edit.Tag ) then // W GLCadencer1Progress() nie dzia�a podczas pauzy.
    begin

      // Pe�ny ekran.

      if Czolgi_Form.BorderStyle <> bsNone then
        begin

          // Pe�ny ekran.

          // Po ustawieniu pe�nego ekranu mog� znika� elementy po�o�one na formie (jak panel), kt�re nie s� wyr�wnywane do bok�w okna.

          window_state_kopia_g := Self.WindowState;

          Czolgi_Form.BorderStyle := bsNone;

          if Czolgi_Form.WindowState = wsMaximized then
            Czolgi_Form.WindowState := wsNormal; // Zmaksymalizowane okno czasami nie zas�ania paska start.

          Czolgi_Form.WindowState := wsMaximized;

        end
      else//if Czolgi_Form.BorderStyle <> bsNone then
        begin

          // Normalny ekran.

          Czolgi_Form.BorderStyle := bsSizeable;
          Czolgi_Form.WindowState := window_state_kopia_g;

        end;
      //---//if Czolgi_Form.BorderStyle <> bsNone then

    end;
  //---//if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Pe�ny_Ekran_Edit.Tag ) then


  if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Pauza_Edit.Tag ) then
    Pauza_ButtonClick( Sender );


  if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Plus_Edit.Tag ) then
    Gra_Wsp�czynnik_Pr�dko�ci_Zmie�( 1 )
  else
  if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__Minus_Edit.Tag ) then
    Gra_Wsp�czynnik_Pr�dko�ci_Zmie�( -1 )
  else
  if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Wsp�czynnik_Pr�dko�ci_Gry__1_Edit.Tag ) then
    Gra_Wsp�czynnik_Pr�dko�ci_Zmie�( 0 )
  else
  if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Edit.Tag ) then
    begin

      if PageControl1.Height <> page_control_1_height_pocz�tkowe then
        PageControl1.Height := page_control_1_height_pocz�tkowe
      else//if PageControl1.Height <> page_control_1_height_pocz�tkowe then
        PageControl1.Height := 1; // 1. Gdy r�wne 0 to po schowaniu nie da si� rozwin�� poprzez Splitter.

      if not Opcje_Splitter.Visible then
        Opcje_Splitter.Visible := true;

    end
  else//if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Opcje__Zwi�_Rozwi�_Edit.Tag ) then
  if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Edit.Tag ) then
    begin

      if PageControl1.Height <> page_control_1_height_pocz�tkowe then
        PageControl1.Height := page_control_1_height_pocz�tkowe
      else//if PageControl1.Height <> page_control_1_height_pocz�tkowe then
        PageControl1.Height := 0; // 1. Gdy r�wne 0 to po schowaniu nie da si� rozwin�� poprzez Splitter.

      Opcje_Splitter.Visible := PageControl1.Height > 0;

    end;
  //---//if GLS.Keyboard.IsKeyDown( Klawiatura__Gra__Opcje__Wy�wietl_Ukryj_Edit.Tag ) then


  if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__Reset_Edit.Tag ) then
    begin

      Gra_GLCamera.ResetRotations();
      Gra_GLCamera.AbsoluteUp := kamera_kopia__up_g;
      Gra_GLCamera.AbsoluteDirection := kamera_kopia__direction_g;
      Gra_GLCamera.AbsolutePosition := kamera_kopia__position_g;

    end;
  //---//if GLS.Keyboard.IsKeyDown( Klawiatura__Kamera__Reset_Edit.Tag ) then


  if Pauza__Sprawd�() then // Gdy pauza jest aktywna.
    Kamera_Ruch( 0.03 );

end;//---//Gra_GLSceneViewerKeyDown().

//GLCollisionManager1Collision().
procedure TCzolgi_Form.GLCollisionManager1Collision( Sender: TObject; object1, object2: TGLBaseSceneObject );

  //Funkcja Oznacz_Kolizj�() w GLCollisionManager1Collision().
  function Oznacz_Kolizj�( object_1_f, object_2_f : TGLBaseSceneObject ) : boolean;
  var
    trafienie_prawid�owe : boolean;
    i : integer;
  begin

    Result := false;

    // Amunicja trafia w amunicj�.
    if    ( not Result )
      and ( object_1_f.Owner is TAmunicja )
      and ( object_2_f.Owner is TAmunicja )
      and ( object_1_f.Owner <> object_2_f.Owner ) // Aby nie oznacza�o kolizji element�w jednej amunicji z sam� sob�.
      and ( not TAmunicja(object_1_f.Owner).czy_usun��_amunicja )
      and ( not TAmunicja(object_2_f.Owner).czy_usun��_amunicja ) then
      begin

        Result := true;

        //Trafienia_Efekt__Utw�rz_Jeden( Gra_Obiekty_GLDummyCube, er_Trafienie_Woda, object_1_f.AbsolutePosition.X, object_1_f.AbsolutePosition.Y, object_1_f.AbsolutePosition.Z, TAmunicja(object_1_f.Owner), -1, -1 );

        TAmunicja(object_1_f.Owner).czy_usun��_amunicja := true;
        TAmunicja(object_2_f.Owner).czy_usun��_amunicja := true;

      end;
    //---//if    ( not Result ) (...)


    // Amunicja trafia w czo�g.
    if    ( not Result )
      and ( object_1_f.Owner is TAmunicja )
      and ( object_2_f.Owner is TCzo�g )
      and ( not TAmunicja(object_1_f.Owner).czy_usun��_amunicja ) then
      begin

        Result := true;

        //TCzo�g(object_2_f.Owner).kad�ub.Material.FrontProperties.Emission.RandomColor();

        TAmunicja(object_1_f.Owner).czy_usun��_amunicja := true;

        // Nieparzyste lewo, parzyste prawo.

        for i := 1 to Length( czo�gi_t ) do
          if czo�gi_t[ i ] = object_2_f.Owner then
            begin

              trafienie_prawid�owe := false;

              // Amunicja leci w prawo i trafia czo�g z prawej strony.
              if    ( not TAmunicja(object_1_f.Owner).lot_w_lewo )
                and ( i mod 2 = 0 ) then
                begin

                  inc( punkty__lewo );
                  trafienie_prawid�owe := true;

                end
              else//if    ( not TAmunicja(object_2_f.Owner).lot_w_lewo ) (...)
              // Amunicja leci w lewo i trafia czo�g z lewej strony.
              if    ( TAmunicja(object_1_f.Owner).lot_w_lewo )
                and ( i mod 2 <> 0 ) then
                begin

                  inc( punkty__prawo );
                  trafienie_prawid�owe := true;

                end;
              //---//if    ( TAmunicja(object_1_f.Owner).lot_w_lewo );


              if trafienie_prawid�owe then
                begin

                  if TAmunicja(object_1_f.Owner).czo�g_indeks_tabeli = Czo�g_Gracza_Indeks_Tabeli_Ustal() then
                    inc( punkty__gracz__1 )
                  else//if i = Czo�g_Gracza_Indeks_Tabeli_Ustal() then
                    if TAmunicja(object_1_f.Owner).czo�g_indeks_tabeli = Czo�g_Gracza_Indeks_Tabeli_Ustal( true ) then
                      inc( punkty__gracz__2 );

                end;
              //---//if trafienie_prawid�owe then


              if czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager <> nil then
                begin

                  czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager.Disabled := false;

                  czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager.IsotropicExplosion
                    (
                      1.1,
                      0,
                      1.1,
                      Round( 500 )
                    );

                end;
              //---//if czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager <> nil then


              if czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager <> nil then
                begin

                  czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager.Maxpoints := efekt__trafienie__alternatywny_gl_thor_fx_manager__maxpoints__enabled_c;

                  czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager.Disabled := false;

                end;
              //---//if czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager <> nil then


              if   ( czo�gi_t[ i ].efekt__trafienie_gl_fire_fx_manager <> nil )
                or ( czo�gi_t[ i ].efekt__trafienie__alternatywny_gl_thor_fx_manager <> nil ) then
                czo�gi_t[ i ].efekt__trafienie_sekundy_czas_i := Czas_Teraz_W_Sekundach();


              Break;

            end;
          //---//if czo�gi_t[ i ] = object_2_f.Owner then

      end;
    //---//if    ( not Result ) (...)


    // Amunicja trafia w prezent.
    if    ( not Result )
      and ( object_1_f.Owner is TAmunicja )
      and ( not TAmunicja(object_1_f.Owner).czy_usun��_amunicja )
      and ( object_2_f.Owner is TPrezent )
      and ( not TPrezent(object_2_f.Owner).czy_prezent_zebrany ) then
      begin

        Result := true;


        TAmunicja(object_1_f.Owner).czy_usun��_amunicja := true;
        TPrezent(object_2_f.Owner).czy_prezent_zebrany := true;


        case TPrezent(object_2_f.Owner).prezent_rodzaj of
            pr_Jazda_Szybsza : czo�gi_t[ TAmunicja(object_1_f.Owner).czo�g_indeks_tabeli ].bonus__jazda_szybsza__zdobycie_sekundy_czas_i := Czas_Teraz_W_Sekundach();
            pr_Prze�adowanie_Szybsze : czo�gi_t[ TAmunicja(object_1_f.Owner).czo�g_indeks_tabeli ].bonus__prze�adowanie_szybsze__zdobycie_sekundy_czas_i := Czas_Teraz_W_Sekundach();
          end;
        //---//case TPrezent(object_2_f.Owner).prezent_rodzaj of


        // Je�eli SI celowa�o w prezent i trafi�o kasuje prezent jako cel.
        if czo�gi_t[ TAmunicja(object_1_f.Owner).czo�g_indeks_tabeli ].si__prezent_cel_x <> null then
          czo�gi_t[ TAmunicja(object_1_f.Owner).czo�g_indeks_tabeli ].si__prezent_cel_x := null;


        TPrezent(object_2_f.Owner).Wygl�d_Zebranie_Ustaw();

      end;
    //---//if    ( not Result ) (...)


    // Amunicja trafia w wa�.
    if    ( not Result )
      and ( object_1_f.Owner is TAmunicja )
      and ( not TAmunicja(object_1_f.Owner).czy_usun��_amunicja )
      and (  not ( object_2_f.Owner is TAmunicja )  )
      and (  not ( object_2_f.Owner is TCzo�g )  )
      and (
               (  object_2_f.Name = Wa�_Lewo_GLCube.Name )
            or (  object_2_f.Name = Wa�_Prawo_GLCube.Name )
          ) then
      begin

        Result := true;

        TAmunicja(object_1_f.Owner).krater_utw�rz := true;
        TAmunicja(object_1_f.Owner).czy_usun��_amunicja := true;

      end;
    //---//if    ( not Result ) (...)

  end;//---//Funkcja Oznacz_Kolizj�() w GLCollisionManager1Collision().

begin//GLCollisionManager1Collision().

  if    ( object1 <> nil )
    and ( object2 <> nil )
    and ( object1.Owner <> nil )
    and ( object2.Owner <> nil ) then
    begin

      if not Oznacz_Kolizj�( object1, object2 ) then
        Oznacz_Kolizj�( object2, object1 );

      //TGLSceneObject(object1).Material.FrontProperties.Emission.RandomColor();

    end;
  //---//if    ( object1 <> nil ) (...)

end;//---//GLCollisionManager1Collision().

//PageControl1Change().
procedure TCzolgi_Form.PageControl1Change( Sender: TObject );
var
  zti : integer;
begin

  if   ( PageControl1.ActivePage = Opcje_TabSheet )
    or ( PageControl1.ActivePage = O_Programie_TabSheet ) then
    begin

      // Przy zmianie zak�adki na Opcje_TabSheet zapami�tuje aktualny rozmiar i zwi�ksza wysoko��.

      if Self.Height >= 430 then
        zti := 330
      else//if Self.Height >= 1050 then
      if Self.Height >= 350 then
        zti := Self.Height - 50
      else//if Self.Height >= 350 then
        zti := 0;

      if    ( Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Checked )
        and ( zti > 0 )
        and ( PageControl1.Height < zti ) then
        begin

          Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Tag := PageControl1.Height;

          PageControl1.Height := zti;

        end;
      //---//if    ( Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Checked ) (...)

    end
  else//if   ( PageControl1.ActivePage = Opcje_TabSheet ) (...)
    begin

      // Przy zmianie zak�adki na inn� ni� Opcje_TabSheet przywraca poprzedni� wysoko��.

      if    ( Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Checked )
        and ( Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Tag > 0 ) then
        PageControl1.Height := Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Tag;


      Opcje__Rozmiar_Zak�adki_Zwi�ksz_CheckBox.Tag := 0;

    end;
  //---//if   ( PageControl1.ActivePage = Opcje_TabSheet ) (...)

end;//---//PageControl1Change().

//Gracz_Czo�g_Wybrany_RadioButtonClick().
procedure TCzolgi_Form.Gracz_Czo�g_Wybrany_RadioButtonClick( Sender: TObject );

  //Funkcja Aktywno��_P�l__Ustaw().
  procedure Aktywno��_P�l__Ustaw( nazwa_klikni�ty_f, nazwa_f : string );
  var
    i_l : integer;
    zts : string;
    zt_component : TComponent;
  begin

    // Ustawia wszystkie pola na aktywne (resetuje ustawienia).
    zt_component := Self.FindComponent( nazwa_f + 'Czo�g_Wybrany_GroupBox' );

    if    ( zt_component <> nil )
      and ( zt_component.ClassType = TGroupBox ) then
      for i_l := 0 to TGroupBox(zt_component).ControlCount - 1 do // Tylko wizualne.
        if TGroupBox(zt_component).Controls[ i_l ].ClassType = TRadioButton then
          TRadioButton(TGroupBox(zt_component).Controls[ i_l ]).Enabled := true;


    if Pos( '__Brak_',  TComponent(Sender).Name ) <= 0 then
      begin

        // Je�eli gracz wybra� czo�g to drugi gracz nie mo�e wybra� tego samego czo�gu (dezaktywuje pole).

        zts := StringReplace( TComponent(Sender).Name, nazwa_klikni�ty_f, nazwa_f, [ rfReplaceAll ] );

        zt_component := Self.FindComponent( zts );

        if    ( zt_component <> nil )
          and ( zt_component.ClassType = TRadioButton ) then
          TRadioButton(zt_component).Enabled := false;

      end;
    //---//if Pos( '__Brak_',  TComponent(Sender).Name ) <= 0 then

  end;//---//Funkcja Aktywno��_P�l__Ustaw().

  //Funkcja Aktywno��_P�l__Sprawd�().
  procedure Aktywno��_P�l__Sprawd�( group_box_f : TGroupBox );
  var
    i_l : integer;
  begin

    //
    // Funkcja sprawdza aby nieaktywne pola nie by�y zaznaczone.
    //

    if group_box_f <> nil then
      for i_l := 0 to group_box_f.ControlCount - 1 do // Tylko wizualne.
        if    ( group_box_f.Controls[ i_l ].ClassType = TRadioButton )
          and ( not TRadioButton(group_box_f.Controls[ i_l ]).Enabled )
          and ( TRadioButton(group_box_f.Controls[ i_l ]).Checked ) then
          TRadioButton(group_box_f.Controls[ i_l ]).Checked := false;

  end;//---//Funkcja Aktywno��_P�l__Sprawd�().

var
  i : integer;
begin//Gracz_Czo�g_Wybrany_RadioButtonClick().

  if    ( Sender <> nil )
    and ( Sender is TRadioButton ) then
    begin

      //???
      //Gracz__1__Czo�g_Wybrany_GroupBox.Enabled := false;
      //Gracz__2__Czo�g_Wybrany_GroupBox.Enabled := false;


      if Pos( 'Gracz__1__',  TComponent(Sender).Name ) > 0 then
        Aktywno��_P�l__Ustaw( 'Gracz__1__', 'Gracz__2__' )
      else//if Pos( 'Gracz__1__',  TComponent(Sender).Name ) > 0 then
        Aktywno��_P�l__Ustaw( 'Gracz__2__', 'Gracz__1__' );


      Aktywno��_P�l__Sprawd�( Gracz__1__Czo�g_Wybrany_GroupBox );
      Aktywno��_P�l__Sprawd�( Gracz__2__Czo�g_Wybrany_GroupBox );


      //???
      //Gracz__1__Czo�g_Wybrany_GroupBox.Enabled := true;
      //Gracz__2__Czo�g_Wybrany_GroupBox.Enabled := true;


      Interfejs_Wska�niki_Ustaw( true );

    end;
  //---//if    ( Sender <> nil ) (...)


  Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox.Enabled := Celownicza_Linia_CheckBox.Checked;

  if    ( not Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox.Enabled )
    and ( Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox.Checked ) then
    Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox.Checked := false;


  for i := 1 to Length( czo�gi_t ) do
    if czo�gi_t[ i ] <> nil then
      begin

        if    ( Celownicza_Linia_CheckBox.Checked )
          and (
                   ( i = Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                or (  i = Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
              ) then
          czo�gi_t[ i ].celownicza_linia.Visible := true
        else//if    ( Celownicza_Linia_CheckBox.Checked ) (...)
          czo�gi_t[ i ].celownicza_linia.Visible := false;

        czo�gi_t[ i ].celownik__koryguj_o_si��_wiatru := Celownicza_Linia__Koryguj_O_Si��_Wiatru_CheckBox.Checked;
        czo�gi_t[ i ].Celownik_Wylicz( Wiatr_Si�a_Modyfikacja_O_Ko�ysanie(), Celownicza_Linia_Wysoko��_SpinEdit.Value );


        if    ( i = Czo�g_Gracza_Indeks_Tabeli_Ustal() )
           or (  i = Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  ) then
          czo�gi_t[ i ].si_decyduje := false
        else//if    ( i = Czo�g_Gracza_Indeks_Tabeli_Ustal() ) (...)
          begin

            //czo�gi_t[ i ].si_decyduje := true;

            if   ( // Je�eli czo�g naprzeciwko gracza nie jest czo�giem innego gracza to sprawdza czy gracz chce gra� przeciwko SI.
                       ( i mod 2 <> 0 ) // Nieparzyste.
                   and (
                           (
                                  ( i <> Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                              and (  i + 1 = Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
                              and ( Gracz__2__Akceptuje_Si_CheckBox.Checked )
                            )
                         or (
                                  (  i <> Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
                              and ( i + 1 = Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                              and ( Gracz__1__Akceptuje_Si_CheckBox.Checked )
                            )
                       )
                 )
              or (
                       ( i mod 2 = 0 ) // Parzyste.
                   and (
                           (
                                  ( i <> Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                              and (  i - 1 = Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
                              and ( Gracz__2__Akceptuje_Si_CheckBox.Checked )
                            )
                         or (
                                  (  i <> Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
                              and ( i - 1 = Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                              and ( Gracz__1__Akceptuje_Si_CheckBox.Checked )
                            )
                       )
                 ) //---// Je�eli czo�g naprzeciwko gracza nie jest czo�giem innego gracza to sprawdza czy gracz chce gra� przeciwko SI.
              or ( // Je�eli czo�gi naprzeciwko siebie nie zosta�y wybrane przez �adnego gracza to sprawdza czy SI ma nimi terowa�.
                       ( Si_Linie_Bez_Graczy_CheckBox.Checked )
                   and ( i <> Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                   and (  i <> Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
                   and (
                            (
                                  ( i mod 2 <> 0 ) // Nieparzyste.
                              and ( i + 1 <> Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                              and (  i + 1 <> Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
                            )
                         or (
                                  ( i mod 2 = 0 ) // Parzyste.
                              and ( i - 1 <> Czo�g_Gracza_Indeks_Tabeli_Ustal() )
                              and (  i - 1 <> Czo�g_Gracza_Indeks_Tabeli_Ustal( true )  )
                            )
                       )
                 ) //---// Je�eli czo�gi naprzeciwko siebie nie zosta�y wybrane przez �adnego gracza to sprawdza czy SI ma nimi terowa�.
              then
              czo�gi_t[ i ].si_decyduje := true
            else//if   ( (...)
              czo�gi_t[ i ].si_decyduje := false;

          end;
        //---//if    ( i = Czo�g_Gracza_Indeks_Tabeli_Ustal() ) (...)

      end;
    //---//if czo�gi_t[ i ] <> nil then

end;//---//Gracz_Czo�g_Wybrany_RadioButtonClick().

//Pauza_ButtonClick().
procedure TCzolgi_Form.Pauza_ButtonClick( Sender: TObject );
begin

  // Pauza podczas wy��czania przeskakuje widokiem kamery gdy obracanie mysz� jest w��czone.

  GLCadencer1.Enabled := not GLCadencer1.Enabled;

  if GLCadencer1.Enabled then
    begin

      // Nie pauza.

      GLCadencer1.TimeMultiplier := gra_wsp�czynnik_pr�dko�ci_g; // Je�eli zmienia si� GLCadencer1.TimeMultiplier podczas pauzy to po wy��czeniu pauzy nast�puje skok w przeliczaniu.
      Pauza_Button.Font.Style := [];

    end
  else//if GLCadencer1.Enabled then
    begin

      // Pauza.

      Pauza_Button.Font.Style := [ fsBold ];

    end;
  //---//if GLCadencer1.Enabled then

  Informacja_Dodatkowa_Timer.Enabled := not GLCadencer1.Enabled;

  Informacja_Dodatkowa__Ustaw();

end;//---//Pauza_ButtonClick().

//Punkty_Zerowanie_BitBtnClick().
procedure TCzolgi_Form.Punkty_Zerowanie_BitBtnClick( Sender: TObject );
begin

  punkty__gracz__1 := 0;
  punkty__gracz__2 := 0;
  punkty__lewo := 0;
  punkty__prawo := 0;

  Interfejs_Wska�niki_Ustaw( true );

end;//---//Punkty_Zerowanie_BitBtnClick().

//Klawiatura_EditKeyDown().
procedure TCzolgi_Form.Klawiatura_EditKeyDown( Sender: TObject; var Key: Word; Shift: TShiftState );
begin

  if   ( Sender = nil )
    or (  not ( Sender is TEdit )  ) then
    Exit;


  // Delete.
  if    ( ssCtrl in Shift )
    and ( Key = 46 ) then
    begin

      TEdit(Sender).Tag := 0;

    end
  else//if    ( ssCtrl in Shift ) (...)
    begin

      TEdit(Sender).Tag := Key;

    end;
  //---//if    ( ssCtrl in Shift ) (...)

  //Key := 0;
  TEdit(Sender).Text := Nazwa_Klawisza( TEdit(Sender).Tag );

  Klawiatura_Konfiguracja__Niepowtarzalno��_Sprawd�();

end;//---//Klawiatura_EditKeyDown().

//Ustawienia__Wczytaj_BitBtnClick().
procedure TCzolgi_Form.Ustawienia__Wczytaj_BitBtnClick( Sender: TObject );
begin

  if Komunikat_Wy�wietl( t�umaczenie_komunikaty_r.komunikat__wczyta�_ustawienia, t�umaczenie_komunikaty_r.komunikat__pytanie, MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
    Exit;


  Ustawienia_Plik();

end;//---//Ustawienia__Wczytaj_BitBtnClick().

//Ustawienia__Zapisz_BitBtnClick().
procedure TCzolgi_Form.Ustawienia__Zapisz_BitBtnClick( Sender: TObject );
begin

  if Komunikat_Wy�wietl( t�umaczenie_komunikaty_r.komunikat__zapisa�_ustawienia, t�umaczenie_komunikaty_r.komunikat__pytanie, MB_YESNO + MB_DEFBUTTON2 + MB_ICONQUESTION ) <> IDYES then
    Exit;

  Ustawienia_Plik( true );

end;//---//Ustawienia__Zapisz_BitBtnClick().

//Dzie�_Noc_CheckBoxClick().
procedure TCzolgi_Form.Dzie�_Noc_CheckBoxClick( Sender: TObject );
begin

  Dzie�_Noc__Procent_TrackBar.Enabled := not Dzie�_Noc_CheckBox.Checked;

  if Dzie�_Noc__Procent_TrackBar.Enabled then
    Dzie�_Noc__Procent_TrackBar.Position := Round( noc_procent );

end;//---//Dzie�_Noc_CheckBoxClick().

//Dzie�_Noc__TrackBarChange().
procedure TCzolgi_Form.Dzie�_Noc__Procent_TrackBarChange( Sender: TObject );
begin

  Dzie�_Noc_Zmie�( 1 );

end;//---//Dzie�_Noc__TrackBarChange().

//Informacja_Dodatkowa_TimerTimer().
procedure TCzolgi_Form.Informacja_Dodatkowa_TimerTimer( Sender: TObject );
begin

  // Aby czas wy�wietlania informacji dodatkowej by� niezale�ny od czasu gry tylko zale�a� od czasu systemowego.

  Informacja_Dodatkowa__Wa�no��_Sprawd�();

end;//---//Informacja_Dodatkowa_TimerTimer().

//Czo�gi_Linia_CheckBoxClick().
procedure TCzolgi_Form.Czo�gi_Linia_CheckBoxClick( Sender: TObject );
begin

  if Sender <> nil then
    begin

      if    (  Length( czo�gi_t ) >= 6  )
        and ( TComponent(Sender).Name = Czo�gi_Linia__3_CheckBox.Name ) then
        begin

          czo�gi_t[ 5 ].Visible := Czo�gi_Linia__3_CheckBox.Checked;
          czo�gi_t[ 6 ].Visible := czo�gi_t[ 5 ].Visible;

        end
      else//if    (  Length( czo�gi_t ) >= 6  ) (...)
      if    (  Length( czo�gi_t ) >= 8  )
        and ( TComponent(Sender).Name = Czo�gi_Linia__4_CheckBox.Name ) then
        begin

          czo�gi_t[ 7 ].Visible := Czo�gi_Linia__4_CheckBox.Checked;
          czo�gi_t[ 8 ].Visible := czo�gi_t[ 7 ].Visible;

        end;
      //---//if    (  Length( czo�gi_t ) >= 6  ) (...)

    end;
  //---//if Sender <> nil then

end;//---//Czo�gi_Linia_CheckBoxClick().

//T�umaczenia_ComboBoxKeyDown().
procedure TCzolgi_Form.T�umaczenia_ComboBoxKeyDown( Sender: TObject; var Key: Word; Shift: TShiftState );
begin

  // Enter.
  if Key = 13 then
    begin

      Key := 0;
      T�umaczenie__Zastosuj();

    end;
  //---//if Key = 13 then

end;//---//T�umaczenia_ComboBoxKeyDown().

//Efekty__Chmury_CheckBoxClick().
procedure TCzolgi_Form.Efekty__Chmury_CheckBoxClick( Sender: TObject );
var
  czy_pauza_l : boolean;
begin

  czy_pauza_l := Pauza__Sprawd�();

  if not czy_pauza_l then
    Pauza_ButtonClick( Sender );


  if Efekty__Chmury_CheckBox.Checked then
    Chmury__Dodaj()
  else
    Chmury__Usu�();


  if not czy_pauza_l then
    Pauza_ButtonClick( Sender );

end;//---//Efekty__Chmury_CheckBoxClick().

//Efekty__Czo�gi__Utw�rz__Zwolnij_CheckBoxClick().
procedure TCzolgi_Form.Efekty__Czo�gi__Utw�rz__Zwolnij_CheckBoxClick( Sender: TObject );
var
  czy_pauza_l : boolean;

  i : integer;
begin

  czy_pauza_l := Pauza__Sprawd�();

  if not czy_pauza_l then
    Pauza_ButtonClick( Sender );


  for i := 1 to Length( czo�gi_t ) do
    if czo�gi_t[ i ] <> nil then
      begin

        czo�gi_t[ i ].Efekty__Trafienie__Zwolnij( not Efekty__Lufa_Wystrza�_CheckBox.Checked, not Efekty__Trafienie_CheckBox.Checked, not Efekty__Trafienie__Alternatywny_CheckBox.Checked );
        czo�gi_t[ i ].Efekty__Trafienie__Utw�rz( GLCadencer1, Efekty__Lufa_Wystrza�_CheckBox.Checked, Efekty__Trafienie_CheckBox.Checked, Efekty__Trafienie__Alternatywny_CheckBox.Checked );

      end;
    //---//if czo�gi_t[ i ] <> nil then


  if not czy_pauza_l then
    Pauza_ButtonClick( Sender );

end;//---//Efekty__Czo�gi__Utw�rz__Zwolnij_CheckBoxClick().

end.

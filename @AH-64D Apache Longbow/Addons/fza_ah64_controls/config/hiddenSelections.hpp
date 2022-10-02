hiddenselections[]={ 
	"skin",
	"skin_fcr",
	"ufd_back",
	"in_lt_apu",
	"mpd_brt",
	"in_backlight",
	"in_backlight2",
	"in_lt_fire1",
	"in_lt_fire1rdy",
	"in_lt_fire2",
	"in_lt_fire2rdy",
	"in_lt_fireapu",
	"in_lt_fireapurdy",
	"in_lt_firepdis",
	"in_lt_firerdis",
	"in_lt_mstrcau",
	"in_lt_mstrwrn",
#define SECTION_A(val)\
	STRINGIFY(GLUE(val,_digit01)),\
	STRINGIFY(GLUE(val,_digit02)),\
	STRINGIFY(GLUE(val,_icon)),
#define SECTION_ASE(val) \
	STRINGIFY(GLUE(val,_digit01)),\
	STRINGIFY(GLUE(val,_digit02)),\
	STRINGIFY(GLUE(val,_icon)),
#define SECTION_B(val) \
	STRINGIFY(GLUE(val,_digit01)),\
	STRINGIFY(GLUE(val,_digit02)),\
	STRINGIFY(GLUE(val,_icon)),
#define SECTION_C(val) \
	STRINGIFY(GLUE(val,_digit01)),\
	STRINGIFY(GLUE(val,_digit02)),\
	STRINGIFY(GLUE(val,_digit03)),
#define SECTION_D(val) \
	STRINGIFY(GLUE(val,_digit01)),\
	STRINGIFY(GLUE(val,_digit02)),\
	STRINGIFY(GLUE(val,_digit03)),\
	STRINGIFY(GLUE(val,_icon)),
#define SECTION_E(val) \
	STRINGIFY(GLUE(val,_digit01)),\
	STRINGIFY(GLUE(val,_digit02)),\
	STRINGIFY(GLUE(val,_digit03)),\
	STRINGIFY(GLUE(val,_digit04)),\
	STRINGIFY(GLUE(val,_digit05)),\
	STRINGIFY(GLUE(val,_digit06)),\
	STRINGIFY(GLUE(val,_digit07)),\
	STRINGIFY(GLUE(val,_digit08)),\
	STRINGIFY(GLUE(val,_digit09)),\
	STRINGIFY(GLUE(val,_digit10)),\
	STRINGIFY(GLUE(val,_digit11)),\
	STRINGIFY(GLUE(val,_icon)),
#define SECTION_FCR(val) \
	STRINGIFY(val),
#define SECTION_PPOS(val) \
	STRINGIFY(GLUE(val,_digit01)),\
	STRINGIFY(GLUE(val,_digit02)),\
	STRINGIFY(GLUE(val,_digit03)),\
	STRINGIFY(GLUE(val,_icon)),
	LIST_OF_BONES(pl)
	LIST_OF_BONES(pr)
	"pl_mpd_back",
	"pr_mpd_back",
	"pl_mpd_tsd",
	"pr_mpd_tsd",
	"tailDigit_01",
	"tailDigit_02",
	"tailDigit_03",
	"tailDigit_04",
	"tailDigit_05",
	"tailDigit_06",
	"tailDigit_07",
};
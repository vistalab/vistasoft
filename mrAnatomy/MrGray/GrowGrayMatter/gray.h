// Gray.h: interface for the CGray class.

//

//////////////////////////////////////////////////////////////////////





class CGray  

{

public:

	void free_gray_matter(GrayMatter *gm);

	GrayMatter * init_gray_matter(MRVol *mrvol);

	int gray_grow_contendp(int, int, int, unsigned char, int, GrayMatter *);

	bool grow_gray_layers(GrayMatter *gm, int voi_xmin, int voi_xmax, int voi_ymin, int voi_ymax, int voi_zmin, int voi_zmax, int num_layers);

	bool add_white_matter(GrayMatter *);

    bool add_white_boundary(GrayMatter *);

    int select_gray_matter_comp(GrayMatter *gm, int startx, int starty, int startz, int SelOrDesel);

    

	CGray();

	bool Ok();

	virtual ~CGray();



	bool m_ContendWhite;

	bool m_ContendGray;



private:

	GrayMatter * alloc_gray_matter(GrayMatter *gm, int inc_size);

	int compute_wm_nbhd_code(unsigned char *,int,int,int, int, int, int, int, int, unsigned char,unsigned char);

	bool first_gray_layer_connectivity(GrayMatter *gm);

	int white_grow_contendp(int, int, int, unsigned char, unsigned char, int, GrayMatter *);

	int find_white_boundary(GrayMatter *, unsigned char, unsigned char, unsigned char, unsigned char);

    int find_white_matter(GrayMatter *, unsigned char, unsigned char, unsigned char, unsigned char);

    int grow_from_white_boundary(GrayMatter *, unsigned char, unsigned char, unsigned char, unsigned char);

	int is_connectedp(int index1, int index2, GrayVoxel *gm_arr);

	int grow_from_gray_boundary(GrayMatter *gm, unsigned char gm_label1, unsigned char gm_label2, unsigned char bg_label);

	int is_connected2p(int index1, int index2,  GrayVoxel *gm_arr);

    int is_connected2s(int index1, int index2,  GrayVoxel *gm_arr);

	bool gray_layer_connectivity(GrayMatter *gm, int first_gv_index, int num_new_gv);

	bool zero_layer_connectivity(GrayMatter *gm, int first_gv_index, int num_new_gv);

    bool zero_layer_full_connectivity(GrayMatter *gm, int first_gv_index, int num_new_gv);

    bool add_new_gray_matter(GrayMatter *gm, int num_new_gv, unsigned char old_label, unsigned char new_label, int layer);

	void gray_matter_set_flag(GrayMatter *gm, unsigned char value);

	int gray_matter_flood_fill(GrayMatter *gm, int index, unsigned char old_value, unsigned char new_value);



	int GrayMatterFlood(GrayMatter *gm, int Seed, unsigned char Old, unsigned char New);



	bool build_rotation_tables(void);

	bool build_type_I_table(void);

	bool build_type_II_table(void);

	bool build_type_III_table(void);



	unsigned char type_I_26nb[6];

	unsigned char type_II_26nb[6];

	unsigned char type_III_26nb[6];



	unsigned char *TYPE_III_TAB;

	unsigned char *TYPE_II_TAB;

	unsigned char *TYPE_I_TAB;

	unsigned char *ROTTAB_ZCCW;

	unsigned char *ROTTAB_ZCW;

	unsigned char *ROTTAB_YCCW;

	unsigned char *ROTTAB_YCW;

	unsigned char *ROTTAB_XCCW;

	unsigned char *ROTTAB_XCW;



	bool m_Ok;

};


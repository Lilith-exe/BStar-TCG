-- Temporary free grading station. Replace this access point with Hardcore
-- Comics authorisation later; no job access or money is assumed in this pass.
Config.Collectibles = {
    binder = { item='bstar_binder', pages=20, pocketsPerPage=9, label='Hardcore Collector Binder' },
    grading = {
        enabled=true, testStation=true, brand='HARDCORE', subtitle='COMICS • CARD GRADING',
        station={id='beach_grading_test',coords={x=-1265.55,y=-1458.30,z=4.18},heading=126.25,
            model='prop_tool_bench02',distance=2.5},
        sealedUnplayable=false
    }
}

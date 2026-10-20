#[test]
fn core_reports_its_health() {
    assert_eq!(omniconvert_core::api::health_check(), "omniconvert-core-ok");
}

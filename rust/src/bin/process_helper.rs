use lopdf::{Document, Object, dictionary};
use std::env;
use std::thread;
use std::time::Duration;

fn main() {
    let mut args = env::args().skip(1);
    match args.next().as_deref() {
        Some("--version") => println!("process-helper 1.0"),
        Some("--fail") => std::process::exit(7),
        Some("--sleep") => thread::sleep(Duration::from_secs(2)),
        Some("--headless") => {
            assert_eq!(args.next().as_deref(), Some("--convert-to"));
            assert_eq!(args.next().as_deref(), Some("pdf"));
            assert_eq!(args.next().as_deref(), Some("--outdir"));
            let output_dir = args.next().expect("output dir");
            let input = std::path::PathBuf::from(args.next().expect("input"));
            let output = std::path::Path::new(&output_dir)
                .join(input.file_stem().unwrap())
                .with_extension("pdf");
            write_pdf(&output);
        }
        Some(input)
            if input.ends_with(".mobi") || input.ends_with(".azw") || input.ends_with(".azw3") =>
        {
            write_pdf(std::path::Path::new(&args.next().expect("output")));
        }
        _ => std::process::exit(2),
    }
}

fn write_pdf(path: &std::path::Path) {
    let mut doc = Document::with_version("1.4");
    let pages = doc.new_object_id();
    let page = doc.add_object(dictionary! {
        "Type" => "Page", "Parent" => pages,
        "MediaBox" => vec![Object::Integer(0), Object::Integer(0), Object::Integer(100), Object::Integer(100)],
    });
    doc.objects.insert(
        pages,
        Object::Dictionary(dictionary! {
            "Type" => "Pages", "Kids" => vec![Object::Reference(page)], "Count" => 1,
        }),
    );
    let catalog = doc.add_object(dictionary! { "Type" => "Catalog", "Pages" => pages });
    doc.trailer.set("Root", catalog);
    doc.save(path).expect("save pdf");
}

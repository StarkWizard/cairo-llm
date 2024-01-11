import os
import argparse
import git
import shutil

def clone_github_repo(repo_url, output_dir):
    parts = repo_url.strip("/").split("/")
    if len(parts) != 2:
        raise ValueError("L'URL du dépôt doit être au format 'utilisateur/nom_du_depot'")
    
    user, repo = parts[0], parts[1]

    repo_path = os.path.join(output_dir, repo)

    if not os.path.exists(repo_path):
        git.Repo.clone_from(f"https://github.com/{user}/{repo}.git", repo_path)

    return repo_path

def get_cairo_files(repo_path, output_dir):
    cairo_files = []
    for root, _, files in os.walk(repo_path):
        for file in files:
            if file.endswith(".cairo"):
                cairo_files.append(os.path.join(root, file))

    project_name = os.path.basename(repo_path)  # Nom du projet à partir du répertoire du dépôt

    project_output_dir = os.path.join(output_dir, project_name+"_cairo")

    os.makedirs(project_output_dir, exist_ok=True)

    for cairo_file in cairo_files:
        file_name = os.path.basename(cairo_file)
        output_file_path = os.path.join(project_output_dir, file_name)
        os.replace(cairo_file, output_file_path)

    shutil.rmtree(repo_path)

    return project_output_dir

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="scrape all the .cairo files from a github repo")
    parser.add_argument("repo_url", help='github repos name using format: "user/repo_name"')
    parser.add_argument("output_dir", help="parent directory for the .cairo files")

    args = parser.parse_args()

    repo_path = clone_github_repo(args.repo_url, args.output_dir)
    cairo_files_dir = get_cairo_files(repo_path, args.output_dir)
    
    print(f"Files are downloaded in : {cairo_files_dir}")

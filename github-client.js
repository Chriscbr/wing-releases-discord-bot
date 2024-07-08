const { Octokit } = require("@octokit/rest");

export async function getCommits(repoOwner, repoName, since, until, token) {
    const octokit = new Octokit({ auth: token });

    try {
        const response = await octokit.rest.repos.listCommits({
            owner: repoOwner,
            repo: repoName,
            since,
            until,
            per_page: 100,
        });

        return response.data.map(commit => ({
            message: commit.commit.message.split('\n')[0],
            author: commit.commit.author.name,
            username: commit.author ? commit.author.login : 'N/A'
        }));
    } catch (error) {
        console.error(`Error fetching commits: ${error.message}`);
    }
}

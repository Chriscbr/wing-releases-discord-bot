const { Octokit } = require("@octokit/rest");
const { DateTime } = require("luxon");

export async function getCommitsSinceLastSunday(repoOwner, repoName, token) {
    const octokit = new Octokit({ auth: token });

    // Get the date of last Sunday at 12:00 UTC
    const lastSunday = DateTime.utc().startOf('week').minus({ weeks: 1 }).plus({ hours: 12 }).toISO();

    try {
        const response = await octokit.rest.repos.listCommits({
            owner: repoOwner,
            repo: repoName,
            since: lastSunday,
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

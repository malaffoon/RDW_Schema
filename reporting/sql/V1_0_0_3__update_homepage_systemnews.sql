# insert or update the html.system-news content for the homepage

USE ${schemaName};

REPLACE INTO translation (label_code, namespace, language_code, label) VALUES ('html.system-news', 'frontend', 'eng', '<h2 class="blue-dark h3 mb-md">Note</h2>
    <div class="summary-reports-container mb-md"><p>Item level data and session IDs are not available for tests administered prior to the 2017-18 school year.</p></div><h2 class="blue-dark h3 mb-md">Known Issues</h2>
    <div class="summary-reports-container mb-md"><ul><li>Student responses for Writing Extended Response (WER) items do not display in the item viewer and will be resolved by September 15th.</li><li>In some cases the school names displayed in this reporting system do not match the names displayed in the legacy reporting system. LEAs should review and update school names in ART to update the school names in the Smarter Balanced reporting system.</li></ul></div>

    <h2 class="blue-dark h3 mb-md">Summary Reports</h2>
    <div class="summary-reports-container mb-md"><p>(Coming Soon)</p></div>
    <h2 class="blue-dark h3 mb-md">Member Reporting Resources</h2>
    <div class="member-reporting-resources-container"><p>(Coming Soon)</p></div>');
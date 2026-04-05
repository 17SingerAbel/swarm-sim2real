$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Escape-XmlText {
    param([string]$Text)
    return [System.Security.SecurityElement]::Escape($Text)
}

function New-Run {
    param(
        [string]$Text,
        [switch]$Bold,
        [string]$Size = '22'
    )

    $escaped = Escape-XmlText $Text
    $rPr = "<w:sz w:val=`"$Size`"/><w:szCs w:val=`"$Size`"/>"
    if ($Bold) {
        $rPr = "<w:b/>$rPr"
    }
    return "<w:r><w:rPr>$rPr</w:rPr><w:t xml:space=`"preserve`">$escaped</w:t></w:r>"
}

function New-Paragraph {
    param(
        [string[]]$Runs,
        [string]$Justification = 'left',
        [int]$SpacingAfter = 120,
        [switch]$KeepNext
    )

    $keepNextXml = ''
    if ($KeepNext) {
        $keepNextXml = '<w:keepNext/>'
    }
    $runXml = ($Runs -join '')
    return "<w:p><w:pPr>$keepNextXml<w:jc w:val=`"$Justification`"/><w:spacing w:after=`"$SpacingAfter`"/></w:pPr>$runXml</w:p>"
}

function New-BulletParagraph {
    param([string]$Text)
    return New-Paragraph -Runs @(
        (New-Run -Text '• ' -Size '22')
        (New-Run -Text $Text -Size '22')
    ) -SpacingAfter 60
}

$outDir = Join-Path $PSScriptRoot '..\..\output\doc'
$outDir = [System.IO.Path]::GetFullPath($outDir)
$tmpDir = Join-Path $PSScriptRoot 'docx_build'
$docxPath = Join-Path $outDir 'interceptor_bidding_analysis.docx'

if (Test-Path $tmpDir) {
    Remove-Item $tmpDir -Recurse -Force
}

New-Item -ItemType Directory -Path $tmpDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tmpDir '_rels') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tmpDir 'word') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tmpDir 'docProps') | Out-Null
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$paragraphs = @()

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'Interceptor Bidding Process Analysis' -Bold -Size '32')
) -Justification 'center' -SpacingAfter 240 -KeepNext

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'Prepared for the MEng project on proactive handover in cooperative multi-target tracking.' -Size '22')
) -Justification 'center' -SpacingAfter 220

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text '1. Problem Currently Addressed by the Code' -Bold -Size '28')
) -SpacingAfter 160 -KeepNext

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'The current interceptor bidding process addresses a prediction-driven interceptor recall and assignment problem. When an active tracker predicts that it will lose a target, the system triggers a handover call and selects new interceptor sensors to move toward a predicted intercept point before the original tracker loses coverage.' -Size '22')
)

$paragraphs += New-BulletParagraph -Text 'For each calling target, the code gathers all eligible candidate sensors.'
$paragraphs += New-BulletParagraph -Text 'Each candidate computes a bid cost, where a lower cost indicates a more suitable interceptor for that target.'
$paragraphs += New-BulletParagraph -Text 'If only one target is calling, the code selects the two lowest-cost interceptors.'
$paragraphs += New-BulletParagraph -Text 'If two targets call at the same time and their best two-sensor teams overlap, the code runs an additional conflict-resolution step to produce a non-overlapping 2-plus-2 assignment.'

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'Therefore, the implemented logic is best viewed as a heuristic interceptor selection mechanism for single-target assignment and a partial conflict-resolution mechanism for the two-target case.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'A key limitation is that simultaneous conflicts involving three or more targets are not fully handled by the current implementation. The existing conflict-resolution branch is effectively complete only for the two-target case.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text '2. Target Research Problem' -Bold -Size '28')
) -SpacingAfter 160 -KeepNext

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'The broader research problem is a global resource-allocation problem with competing targets and limited interceptor resources.' -Size '22')
)

$paragraphs += New-BulletParagraph -Text 'There are k targets that may simultaneously request interceptor support.'
$paragraphs += New-BulletParagraph -Text 'Each target can be assigned at most m interceptors.'
$paragraphs += New-BulletParagraph -Text 'A pool of idle or reassignable sensors is available as interceptor candidates.'
$paragraphs += New-BulletParagraph -Text 'Each candidate sensor has a target-dependent assignment cost.'
$paragraphs += New-BulletParagraph -Text 'The system should maintain unique assignment, so one interceptor cannot be assigned to multiple targets at the same time.'
$paragraphs += New-BulletParagraph -Text 'The system should assign as many interceptors as possible, ideally up to m per target, and only leave a target under-served when the candidate pool is insufficient.'
$paragraphs += New-BulletParagraph -Text 'After maximizing feasible coverage, the overall assignment cost should be minimized.'

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'A natural development path is to first optimize the special case k = 2 and m = 2, and then generalize the formulation to arbitrary k and m.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text '3. Mathematical Form of the Current Method' -Bold -Size '28')
) -SpacingAfter 160 -KeepNext

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'Let T = {1, ..., k} denote the set of calling targets, and let S = {1, ..., n} denote the set of eligible interceptor candidates. Let c_(i,t) be the bid cost of assigning sensor i to target t.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'In the current code, the bid is a weighted sum:' -Size '22')
) -KeepNext

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'c_(i,t) = w1 P_home(i) + w2 P_spatial(i,t) + w3 P_temporal(i,t) + w4 P_uncertainty(i,t)' -Bold -Size '22')
) -Justification 'center' -SpacingAfter 140

$paragraphs += New-BulletParagraph -Text 'P_home penalizes the displacement of a sensor from its home location.'
$paragraphs += New-BulletParagraph -Text 'P_spatial penalizes the distance from the sensor to the target intercept point.'
$paragraphs += New-BulletParagraph -Text 'P_temporal penalizes poor arrival timing relative to the target motion.'
$paragraphs += New-BulletParagraph -Text 'P_uncertainty penalizes low shared confidence in the target estimate.'

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'For a single target t, the current logic is equivalent to the following binary optimization problem:' -Size '22')
) -KeepNext

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'min   sum over i in S of c_(i,t) x_(i,t)' -Bold -Size '22')
) -Justification 'center' -SpacingAfter 60
$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'subject to   sum over i in S of x_(i,t) = 2' -Bold -Size '22')
) -Justification 'center' -SpacingAfter 60
$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'x_(i,t) in {0,1}' -Bold -Size '22')
) -Justification 'center' -SpacingAfter 140

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'Because the team cost is additive, the implementation simply selects the two lowest-cost sensors for the calling target.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'For two simultaneous targets, the code applies a repair-based strategy:' -Size '22')
) -KeepNext

$paragraphs += New-BulletParagraph -Text 'First, it independently computes the best two-sensor team for each target.'
$paragraphs += New-BulletParagraph -Text 'Second, it checks whether the selected teams overlap.'
$paragraphs += New-BulletParagraph -Text 'If overlap exists, it performs a minimax-style enumeration over a reduced candidate subset and selects the non-overlapping assignment that minimizes the worst team cost.'

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'This means the current approach does not solve one unified global optimization problem. Instead, it first obtains local optima and then repairs conflicts when necessary.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text '4. Why the Current Method is Sub-optimal' -Bold -Size '28')
) -SpacingAfter 160 -KeepNext

$paragraphs += New-BulletParagraph -Text 'It is not a single globally optimized formulation.'
$paragraphs += New-BulletParagraph -Text 'It may miss better global assignments because it starts from per-target local minima.'
$paragraphs += New-BulletParagraph -Text 'Its objective changes across cases: single-target selection minimizes additive cost, while conflict repair for two targets uses a minimax criterion.'
$paragraphs += New-BulletParagraph -Text 'The method is only fully implemented for the two-target simultaneous-conflict case.'
$paragraphs += New-BulletParagraph -Text 'It does not rigorously encode the priority of maximizing assignment coverage before minimizing cost.'
$paragraphs += New-BulletParagraph -Text 'When the candidate pool is insufficient, it does not provide a clean and systematic partial-allocation rule.'

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'Its main strengths are simplicity, low computational burden, and easy integration into the current monolithic MATLAB simulation. Therefore, it is best described as a practical conflict-aware heuristic rather than a globally optimal multi-target allocation algorithm.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text '5. More Efficient and More Optimal Alternatives' -Bold -Size '28')
) -SpacingAfter 160 -KeepNext

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'A more systematic solution is to formulate the interceptor assignment as a global constrained optimization problem.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'Let x_(i,t) = 1 if sensor i is assigned to target t, and 0 otherwise.' -Size '22')
) -KeepNext

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'sum over t in T of x_(i,t) <= 1    for all sensors i' -Bold -Size '22')
) -Justification 'center' -SpacingAfter 60
$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'sum over i in S of x_(i,t) <= m    for all targets t' -Bold -Size '22')
) -Justification 'center' -SpacingAfter 60
$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'x_(i,t) in {0,1}' -Bold -Size '22')
) -Justification 'center' -SpacingAfter 140

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'A suitable lexicographic objective is:' -Size '22')
) -KeepNext

$paragraphs += New-BulletParagraph -Text 'First, maximize the total number of assigned interceptor slots.'
$paragraphs += New-BulletParagraph -Text 'Second, among all maximum-coverage assignments, minimize the total assignment cost.'

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'Equivalently, one may introduce shortage variables u_t = m - sum over i in S of x_(i,t) and minimize shortage before minimizing cost. This directly captures the requirement that each target should receive as many interceptors as possible, and only be under-served when the candidate pool is insufficient.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'Two strong algorithmic options follow from this formulation.' -Size '22')
)

$paragraphs += New-BulletParagraph -Text 'Min-cost max-flow: Duplicate each target into m target slots, connect each sensor to eligible slots with edge cost c_(i,t), and solve a global min-cost max-flow problem. This gives an exact and computationally efficient solution for the small and medium-size instances relevant to this project.'
$paragraphs += New-BulletParagraph -Text 'MILP: Use binary decision variables and solve the allocation as a mixed-integer linear program. This is clean to present mathematically and also yields a global optimum at the current problem scale.'

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'For the current simulation scale, such as up to 25 sensors, 3 targets, and 2 interceptor slots per target, both approaches are computationally practical and are far more systematic than pairwise conflict repair.' -Size '22')
)

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text '6. Recommended Research Positioning' -Bold -Size '28')
) -SpacingAfter 160 -KeepNext

$paragraphs += New-Paragraph -Runs @(
    (New-Run -Text 'A clear research narrative is the following. The current code uses a heuristic bidding and conflict-resolution scheme that works reasonably for single-target assignment and partially for the two-target case. However, it is not a unified global optimizer and does not naturally scale to general multi-target competition. A stronger formulation is to model interceptor selection as a capacity-constrained global assignment problem and solve it using min-cost max-flow or MILP. This provides guaranteed uniqueness, graceful degradation when resources are insufficient, and globally optimal assignments under the stated objective.' -Size '22')
)

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
 xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
 xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
 xmlns:v="urn:schemas-microsoft-com:vml"
 xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
 xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
 xmlns:w10="urn:schemas-microsoft-com:office:word"
 xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
 xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
 xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
 xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
 xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
 xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
 mc:Ignorable="w14 wp14">
  <w:body>
    $($paragraphs -join "`n    ")
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/>
      <w:cols w:space="708"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$contentTypesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
"@

$relsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"@

$coreXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
 xmlns:dcmitype="http://purl.org/dc/dcmitype/"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Interceptor Bidding Process Analysis</dc:title>
  <dc:creator>Codex</dc:creator>
  <cp:lastModifiedBy>Codex</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">2026-03-20T00:00:00Z</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">2026-03-20T00:00:00Z</dcterms:modified>
</cp:coreProperties>
"@

$appXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
 xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Codex</Application>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <SharedDoc>false</SharedDoc>
  <HyperlinksChanged>false</HyperlinksChanged>
  <AppVersion>1.0</AppVersion>
</Properties>
"@

[System.IO.File]::WriteAllText((Join-Path $tmpDir '[Content_Types].xml'), $contentTypesXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $tmpDir '_rels\.rels'), $relsXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $tmpDir 'word\document.xml'), $documentXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $tmpDir 'docProps\core.xml'), $coreXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $tmpDir 'docProps\app.xml'), $appXml, [System.Text.UTF8Encoding]::new($false))

if (Test-Path $docxPath) {
    Remove-Item $docxPath -Force
}

[System.IO.Compression.ZipFile]::CreateFromDirectory($tmpDir, $docxPath)
Write-Output "Created: $docxPath"

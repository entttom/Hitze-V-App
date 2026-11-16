@file:OptIn(ExperimentalMaterial3Api::class)

package org.entner.HitzeV.ui.addworkplace

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import org.entner.HitzeV.AddWorkplaceFormState
import org.entner.HitzeV.AddWorksiteError
import org.entner.HitzeV.AddressSearchMessage
import org.entner.HitzeV.model.AddressSearchResult
import org.entner.HitzeV.ui.components.BackTopAppBar
import org.entner.HitzeV.ui.components.HeroSheetCard
import org.entner.HitzeV.ui.components.HitzeVPreviews
import org.entner.HitzeV.ui.components.LocalCopybook
import org.entner.HitzeV.ui.components.PreviewSurface
import org.entner.HitzeV.ui.components.SectionCard
import org.entner.HitzeV.ui.components.SectionHeading
import org.entner.HitzeV.ui.components.readableWidth
import org.entner.HitzeV.ui.copy.Copybook

@Stable
interface AddWorkplaceActions {
    fun onBack()
    fun onNameChanged(value: String)
    fun onAddressChanged(value: String)
    fun onSearch()
    fun onUseAddress(result: AddressSearchResult)
    fun onDismissError()
}

@Composable
fun AddWorkplaceScreen(form: AddWorkplaceFormState, actions: AddWorkplaceActions) {
    val copy = LocalCopybook.current
    val addressFocusRequester = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current
    val layoutDirection = LocalLayoutDirection.current
    val inputsEnabled = !form.isAdding

    LaunchedEffect(Unit) {
        runCatching { addressFocusRequester.requestFocus() }
    }

    form.addError?.let { error ->
        AlertDialog(
            onDismissRequest = actions::onDismissError,
            title = { Text(copy.addWorkplaceFailureTitle) },
            text = { Text(error.message(copy)) },
            confirmButton = {
                TextButton(onClick = actions::onDismissError) { Text(copy.okButton) }
            }
        )
    }

    val search = {
        keyboard?.hide()
        actions.onSearch()
    }

    Scaffold(
        contentWindowInsets = WindowInsets.safeDrawing,
        topBar = { BackTopAppBar(title = copy.addWorkplaceTitle, onBack = actions::onBack) }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = innerPadding.calculateTopPadding())
                .imePadding(),
            contentAlignment = Alignment.TopCenter
        ) {
            LazyColumn(
                modifier = Modifier
                    .readableWidth()
                    .fillMaxHeight(),
                contentPadding = PaddingValues(
                    start = innerPadding.calculateStartPadding(layoutDirection) + 16.dp,
                    end = innerPadding.calculateEndPadding(layoutDirection) + 16.dp,
                    top = 8.dp,
                    bottom = innerPadding.calculateBottomPadding() + 24.dp
                ),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item(key = "hero") {
                    HeroSheetCard(title = copy.addWorkplaceTitle, body = copy.addWorkplaceHeroBody)
                }

                item(key = "form") {
                    SectionCard {
                        ClearableTextField(
                            label = copy.namePlaceholder,
                            value = form.nameInput,
                            placeholder = copy.optionalFieldPlaceholder,
                            enabled = inputsEnabled,
                            onValueChange = actions::onNameChanged,
                            imeAction = ImeAction.Next
                        )
                        ClearableTextField(
                            label = copy.addressPlaceholder,
                            value = form.addressQuery,
                            placeholder = copy.addressFieldHint,
                            enabled = inputsEnabled,
                            onValueChange = actions::onAddressChanged,
                            modifier = Modifier.focusRequester(addressFocusRequester),
                            imeAction = ImeAction.Search,
                            keyboardActions = KeyboardActions(onSearch = { if (form.canSearch) search() }),
                            leadingIcon = { Icon(Icons.Rounded.Search, contentDescription = null) }
                        )
                        Button(
                            onClick = search,
                            enabled = form.canSearch,
                            modifier = Modifier.fillMaxWidth(),
                            contentPadding = PaddingValues(vertical = 14.dp)
                        ) {
                            if (form.isSearching) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(18.dp),
                                    strokeWidth = 2.dp,
                                    color = MaterialTheme.colorScheme.onPrimary
                                )
                            } else {
                                Icon(Icons.Rounded.Search, contentDescription = null)
                            }
                            Text(copy.searchAddressButton, modifier = Modifier.padding(start = 8.dp))
                        }
                    }
                }

                form.message?.let { message ->
                    item(key = "message") {
                        Surface(
                            shape = RoundedCornerShape(16.dp),
                            color = MaterialTheme.colorScheme.surfaceContainerHigh,
                            modifier = Modifier
                                .fillMaxWidth()
                                .semantics { liveRegion = LiveRegionMode.Polite }
                        ) {
                            Text(
                                text = message.text(copy),
                                style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.padding(14.dp)
                            )
                        }
                    }
                }

                if (form.results.isNotEmpty()) {
                    item(key = "resultsHeading") {
                        SectionHeading(title = copy.searchResultsTitle)
                    }
                    items(form.results, key = { it.id }) { result ->
                        AddressResultCard(
                            result = result,
                            isAdding = form.addingResultId == result.id,
                            enabled = !form.isAdding,
                            onUse = { actions.onUseAddress(result) }
                        )
                    }
                }
            }
        }
    }
}

private fun AddressSearchMessage.text(copy: Copybook): String = when (this) {
    AddressSearchMessage.ENTER_ADDRESS -> copy.enterAddressMessage
    AddressSearchMessage.NO_RESULTS -> copy.noAddressFoundMessage
    AddressSearchMessage.SEARCH_FAILED -> copy.addressSearchFailedMessage
}

private fun AddWorksiteError.message(copy: Copybook): String = when (this) {
    AddWorksiteError.OUTSIDE_AUSTRIA -> copy.addOutsideAustriaMessage
    AddWorksiteError.NETWORK -> copy.liveDataUnavailableMessage
    AddWorksiteError.OTHER -> copy.workplaceCouldNotBeAddedMessage
}

@Composable
private fun ClearableTextField(
    label: String,
    value: String,
    placeholder: String,
    enabled: Boolean,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    imeAction: ImeAction = ImeAction.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    leadingIcon: @Composable (() -> Unit)? = null
) {
    val copy = LocalCopybook.current
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier.fillMaxWidth(),
        enabled = enabled,
        label = { Text(label) },
        placeholder = { Text(placeholder) },
        leadingIcon = leadingIcon,
        trailingIcon = if (value.isNotEmpty() && enabled) {
            {
                IconButton(onClick = { onValueChange("") }) {
                    Icon(Icons.Rounded.Close, contentDescription = "${copy.clearTextLabel}: $label")
                }
            }
        } else {
            null
        },
        shape = RoundedCornerShape(16.dp),
        keyboardOptions = KeyboardOptions(imeAction = imeAction),
        keyboardActions = keyboardActions,
        singleLine = true
    )
}

@Composable
private fun AddressResultCard(
    result: AddressSearchResult,
    isAdding: Boolean,
    enabled: Boolean,
    onUse: () -> Unit
) {
    val copy = LocalCopybook.current
    val shape = RoundedCornerShape(20.dp)
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .clickable(enabled = enabled, onClickLabel = copy.useAddressButton, role = Role.Button, onClick = onUse),
        shape = shape,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(Icons.Rounded.LocationOn, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(result.title, style = MaterialTheme.typography.titleMedium)
                Text(
                    result.subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (isAdding) {
                CircularProgressIndicator(modifier = Modifier.size(24.dp), strokeWidth = 2.dp)
            } else {
                Text(
                    copy.useAddressButton,
                    style = MaterialTheme.typography.labelLarge,
                    color = if (enabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

private object PreviewAddWorkplaceActions : AddWorkplaceActions {
    override fun onBack() = Unit
    override fun onNameChanged(value: String) = Unit
    override fun onAddressChanged(value: String) = Unit
    override fun onSearch() = Unit
    override fun onUseAddress(result: AddressSearchResult) = Unit
    override fun onDismissError() = Unit
}

@HitzeVPreviews
@Composable
private fun AddWorkplaceScreenPreview() {
    PreviewSurface {
        AddWorkplaceScreen(
            form = AddWorkplaceFormState(
                nameInput = "Baustelle",
                addressQuery = "Hauptplatz Graz",
                results = listOf(
                    AddressSearchResult("1", "Hauptplatz", "Hauptplatz, 8010 Graz, Steiermark, Österreich", 47.07, 15.43),
                    AddressSearchResult("2", "Hauptplatz", "Hauptplatz, 4020 Linz, Oberösterreich, Österreich", 48.30, 14.29)
                ),
                addingResultId = "1"
            ),
            actions = PreviewAddWorkplaceActions
        )
    }
}
